defmodule MtgFriendsWeb.TournamentLive.Show do
  use MtgFriendsWeb, :live_view

  alias MtgFriendsWeb.UserAuth
  alias MtgFriendsWeb.Live.TournamentLive.Utils
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

    num_pairings = round(Float.ceil(length(tournament.participants) / 4))

    participant_score_lookup =
      Utils.get_overall_scores(tournament.rounds, num_pairings, true)
      |> Map.new(fn %{id: id, total_score: total_score, win_rate: win_rate} ->
        {id, %{total_score: total_score, win_rate: win_rate}}
      end)

    participant_forms =
      to_form(%{
        "participants" =>
          tournament.participants
          |> Enum.map(fn participant ->
            %{
              "id" => participant.id,
              "name" => participant.name,
              "decklist" => participant.decklist,
              "scores" => Map.get(participant_score_lookup, participant.id, nil)
            }
          end)
          # Sort players by highest -> lowest overall scores
          |> Enum.sort_by(fn x -> x["scores"] && x["scores"].total_score end, :desc)
      })

    %{current_user: current_user, live_action: live_action} = socket.assigns

    {
      :noreply,
      socket
      |> UserAuth.assign_current_user_owner(current_user, tournament)
      |> assign(:page_title, page_title(live_action))
      |> assign(:tournament, tournament)
      |> assign(:rounds, tournament.rounds)
      |> assign(
        :current_round_active,
        with len <- length(tournament.rounds), true <- len > 0 do
          Map.get(Enum.at(tournament.rounds, len - 1), :active, false)
        else
          _ -> false
        end
      )
      |> assign(
        :all_participants_have_names,
        Enum.all?(tournament.participants, fn p -> not is_nil(p.name) end)
      )
      |> assign(
        :has_enough_participants,
        length(tournament.participants) >= 6
      )
      |> assign(:participant_forms, participant_forms)
      |> assign(:toggle_score_decimals, true)
    }
  end

  defp page_title(:show), do: "Show Tournament"
  defp page_title(:edit), do: "Edit Tournament"

  @impl true
  def handle_event("create-round", %{"mode" => mode} = _, socket) do
    tournament = socket.assigns.tournament
    first_round? = length(tournament.rounds) == 0

    case Rounds.create_round(
           tournament.id,
           length(tournament.rounds)
         ) do
      {:ok, round} ->
        case Utils.create_pairings(
               tournament,
               round,
               case mode do
                 "normal" -> false
                 "top-cut-4" -> true
               end
             ) do
          {:ok, _} ->
            if first_round? do
              {:ok, _} = Tournaments.update_tournament(tournament, %{"status" => :active})
            end

            {:noreply,
             socket
             |> put_flash(:info, "Round #{round.number + 1} created successfully")
             |> push_navigate(to: ~p"/tournaments/#{tournament.id}/rounds/#{round.number + 1}")}

          {:error, _} ->
            {:noreply,
             put_flash(socket, :error, "Something wrong happened when creating a round")}
        end

      {:error, %Ecto.Changeset{} = _} ->
        {:noreply, put_flash(socket, :error, "Something wrong happened when creating a round")}
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

  @impl true
  def handle_event("toggle-score-decimals", _, socket) do
    {:noreply,
     assign(socket, :toggle_score_decimals, not Map.get(socket.assigns, :toggle_score_decimals))}
  end

  defp reload_page(socket) do
    socket |> push_navigate(to: ~p"/tournaments/#{socket.assigns.tournament.id}", replace: true)
  end
end
