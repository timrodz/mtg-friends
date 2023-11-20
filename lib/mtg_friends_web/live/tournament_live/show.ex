defmodule MtgFriendsWeb.TournamentLive.Show do
  use MtgFriendsWeb, :live_view

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
    rounds = tournament.rounds

    num_pairings = round(Float.ceil(length(tournament.participants) / 4))

    participant_scores = get_participant_scores(rounds, num_pairings)

    participant_forms =
      to_form(%{
        "participants" =>
          tournament.participants
          |> Enum.map(fn participant ->
            %{
              "id" => participant.id,
              "name" => participant.name,
              "decklist" => participant.decklist,
              "scores" => Map.get(participant_scores, participant.id, nil)
            }
          end)
          |> Enum.sort_by(fn x -> x["scores"] && x["scores"].total_score end, :desc)
      })

    %{current_user: current_user, live_action: live_action} = socket.assigns

    {
      :noreply,
      socket
      |> assign(:page_title, page_title(live_action))
      |> Utils.assign_current_user_tournament_owner(current_user, tournament)
      |> assign(:tournament, tournament)
      |> assign(:rounds, tournament.rounds)
      |> assign(
        :current_round_active,
        with len <- length(tournament.rounds), true <- len > 0 do
          Map.get(Enum.at(tournament.rounds, len - 1), :active, false)
          |> IO.inspect()
        else
          _ -> false
        end
      )
      |> assign(
        :all_participants_have_names,
        Enum.all?(tournament.participants, fn p -> not is_nil(p.name) end)
      )
      |> assign(:participant_forms, participant_forms)
    }
  end

  defp page_title(:show), do: "Show Tournament"
  defp page_title(:edit), do: "Edit Tournament"

  @impl true
  def handle_event("save-participants", params, socket) do
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
  def handle_event("create-round", _, socket) do
    tournament = socket.assigns.tournament

    case Rounds.create_round(
           tournament.id,
           length(tournament.rounds)
         ) do
      {:ok, round} ->
        {:noreply,
         socket
         |> put_flash(:info, "Round #{round.number + 1} created successfully")
         |> reload_page()}

      {:error, %Ecto.Changeset{} = _} ->
        {:noreply, put_flash(socket, :error, "Something wrong happened when creating a round")}
    end
  end

  @impl true
  def handle_event("add-participant", _, socket) do
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

  defp get_participant_scores(rounds, num_pairings) do
    rounds
    |> Enum.flat_map(fn round -> round.pairings end)
    |> Enum.group_by(&Map.get(&1, :participant_id))
    |> Enum.map(fn {id, p} ->
      total_wins = Enum.reduce(p, 0, fn i, acc -> (i.winner && 1 + acc) || acc end)

      %{
        "id" => id,
        "total_score" =>
          Enum.reduce(p, 0, fn cur_pairing, acc ->
            calculate_scores(rounds, num_pairings, p, cur_pairing, acc)
          end)
          |> IO.inspect(label: "num")
          |> Decimal.from_float()
          |> Decimal.round(3),
        "win_rate" =>
          "#{(total_wins / length(rounds) * 100) |> Decimal.from_float() |> Decimal.round(2)}%"
      }
    end)
    |> Map.new(fn %{"id" => k, "total_score" => total_score, "win_rate" => win_rate} ->
      {k, %{total_score: total_score, win_rate: win_rate}}
    end)
  end

  defp calculate_scores(rounds, num_pairings, p, cur_pairing, acc) do
    cur_round = Enum.find(rounds, fn r -> r.id == cur_pairing.round_id end)

    case cur_round.number do
      0 ->
        cur_pairing.points + 0.0 + acc

      _ ->
        {decimals, ""} =
          Float.parse("0.00#{num_pairings - cur_pairing.number}") |> IO.inspect()

        cur_pairing.points + decimals + acc
    end
  end

  defp reload_page(socket) do
    socket |> push_navigate(to: ~p"/tournaments/#{socket.assigns.tournament.id}")
  end
end
