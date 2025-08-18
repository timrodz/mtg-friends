defmodule MtgFriendsWeb.TournamentLive.Show do
  use MtgFriendsWeb, :live_view

  alias MtgFriends.{TournamentUtils, TournamentRenderer}
  alias MtgFriendsWeb.UserAuth
  alias MtgFriends.Tournaments
  alias MtgFriends.Participants
  alias MtgFriends.Rounds

  on_mount {MtgFriendsWeb.UserAuth, :mount_current_user}

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    tournament = Tournaments.get_tournament!(id)

    num_pairings =
      TournamentUtils.get_num_pairings(length(tournament.participants), tournament.format)

    participant_score_lookup =
      TournamentUtils.get_overall_scores(tournament.rounds, num_pairings)
      |> Map.new(fn %{id: id, total_score: total_score, win_rate: win_rate} ->
        {id,
         %{
           total_score: total_score,
           total_score_sort_by: total_score |> Decimal.round(3),
           win_rate: win_rate
         }}
      end)

    winner =
      case tournament.status == :finished do
        false ->
          nil

        true ->
          tournament.participants |> Enum.find(fn p -> p.is_tournament_winner == true end)
      end

    participant_forms =
      to_form(%{
        "participants" =>
          tournament.participants
          |> Enum.map(fn participant ->
            %{
              "id" => participant.id,
              "name" => participant.name,
              "decklist" => participant.decklist,
              "is_tournament_winner" => participant.is_tournament_winner,
              "is_dropped" => participant.is_dropped,
              "scores" => Map.get(participant_score_lookup, participant.id, nil)
            }
          end)
          # Sort players by winner & highest to lowest overall scores
          |> Enum.sort_by(
            &{&1["is_tournament_winner"],
             (&1["scores"] && &1["scores"].total_score_sort_by) || nil},
            :desc
          )
      })

    %{current_user: current_user, live_action: live_action} = socket.assigns

    {
      :noreply,
      socket
      |> UserAuth.assign_current_user_owner(current_user, tournament)
      |> UserAuth.assign_current_user_admin(socket.assigns.current_user)
      |> assign(:has_winner?, not is_nil(winner))
      |> assign(:page_title, page_title(live_action, tournament.name))
      |> assign(:tournament, tournament)
      |> assign(:rounds, tournament.rounds)
      |> assign(
        :is_current_round_active?,
        with len <- length(tournament.rounds), true <- len > 0 do
          round = Enum.at(tournament.rounds, len - 1)
          status = Map.get(round, :status)
          status != :finished
        else
          _ -> false
        end
      )
      |> assign(
        :all_participants_have_names?,
        Enum.all?(tournament.participants, fn p -> not is_nil(p.name) end)
      )
      |> assign(
        :has_enough_participants?,
        length(tournament.participants) >= 4
      )
      |> assign(:participant_forms, participant_forms)
    }
  end

  defp page_title(:show, tournament_name), do: "#{tournament_name}"
  defp page_title(:edit, tournament_name), do: "Edit #{tournament_name}"
  defp page_title(:end, tournament_name), do: "Finish #{tournament_name}"

  @impl true
  def handle_event("create-round", _, socket) do
    tournament = socket.assigns.tournament
    round_count = length(tournament.rounds)
    first_round? = round_count == 0

    with {:ok, round} <-
           Rounds.create_round_for_tournament(
             tournament.id,
             round_count
           ),
         {:ok, _} <-
           TournamentUtils.create_pairings(
             tournament,
             round
           ) do
      if first_round? do
        {:ok, _} = Tournaments.update_tournament(tournament, %{"status" => :active})
      end

      {:noreply,
       socket
       |> put_flash(:info, "Round #{round.number + 1} created successfully")
       |> push_navigate(to: ~p"/tournaments/#{tournament.id}/rounds/#{round.number + 1}")}
    else
      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Something wrong happened when creating a round")}

      {:error, %Ecto.Changeset{} = _} ->
        {:noreply, put_flash(socket, :error, "Something wrong happened when creating a round")}

      _ ->
        nil
    end
  end

  @impl true
  def handle_event("create-participant", _, socket) do
    tournament_id = socket.assigns.tournament.id

    case Participants.create_empty_participant(tournament_id) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Participant created successfully")
         |> reload_page()}

      {:error, %Ecto.Changeset{} = _} ->
        {:noreply,
         put_flash(socket, :error, "Something wrong happened when adding a participant")}
    end
  end

  @impl true
  def handle_event("update-participants", params, socket) do
    tournament = socket.assigns.tournament

    case Participants.update_participants_for_tournament(
           tournament.id,
           tournament.participants,
           params
         ) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Tournament updated successfully")
         |> reload_page()}

      {:error, _, error, _} ->
        {:noreply, socket |> put_flash(:error, error)}

      {:error, :no_changes_detected} ->
        {:noreply, socket |> put_flash(:warning, "No changes detected")}
    end
  end

  @impl true
  def handle_event("delete-participant", %{"id" => id}, socket) do
    participant = Participants.get_participant!(id)
    {:ok, _} = Participants.delete_participant(participant)

    {:noreply, reload_page(socket)}
  end

  @impl true
  def handle_event("drop-participant", %{"id" => id}, socket) do
    participant = Participants.get_participant!(id)
    IO.puts("dropping #{id}")
    {:ok, _} = Participants.update_participant(participant, %{"is_dropped" => true})

    {:noreply, reload_page(socket)}
  end

  @impl true
  def handle_event("delete-round", %{"id" => id}, socket) do
    round = Rounds.get_round!(id)
    {:ok, _} = Rounds.delete_round(round)

    {:noreply, reload_page(socket)}
  end

  @impl true
  def handle_event("finish-tournament", _, socket) do
    tournament = socket.assigns.tournament

    {:ok, _} = Tournaments.update_tournament(tournament, %{"status" => :finished})

    {:noreply, socket |> put_flash(:info, "Tournament is now finished") |> reload_page()}
  end

  defp reload_page(socket) do
    socket |> push_navigate(to: ~p"/tournaments/#{socket.assigns.tournament.id}", replace: true)
  end
end
