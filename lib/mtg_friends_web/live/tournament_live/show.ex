defmodule MtgFriendsWeb.TournamentLive.Show do
  use MtgFriendsWeb, :live_view

  alias MtgFriendsWeb.Live.TournamentLive.Utils
  alias MtgFriends.Tournaments
  alias MtgFriends.Rounds
  alias MtgFriends.Participants
  alias MtgFriends.Participants.Participant

  on_mount {MtgFriendsWeb.UserAuth, :mount_current_user}

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    tournament = Tournaments.get_tournament!(id)
    rounds = tournament.rounds

    participant_scores =
      rounds
      |> Enum.flat_map(fn round -> round.pairings end)
      |> Enum.group_by(&Map.get(&1, :participant_id), fn x -> x.points end)
      |> Enum.map(fn {id, p} ->
        %{"id" => id, "total_score" => Enum.reduce(p, 0, fn i, acc -> i + acc end)}
      end)
      |> Map.new(fn %{"id" => k, "total_score" => v} -> {k, v} end)

    participant_forms =
      to_form(%{
        "participants" =>
          tournament.participants
          |> Enum.map(fn participant ->
            %{
              "id" => participant.id,
              "name" => participant.name,
              "decklist" => participant.decklist || "",
              "total_score" => Map.get(participant_scores, participant.id, 0)
            }
          end)
          |> Enum.sort_by(fn x -> x["total_score"] end, :desc)
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
        :all_participants_have_names,
        Enum.all?(tournament.participants, fn p -> not is_nil(p.name) end)
      )
      |> assign(:participant_forms, participant_forms)
    }
  end

  defp page_title(:show), do: "Show Tournament"
  defp page_title(:edit), do: "Edit Tournament"

  defp build_participant_form(item_or_changeset, params, action \\ nil) do
    changeset =
      item_or_changeset
      |> Participants.change_participant(params)
      |> Map.put(:action, action)

    to_form(changeset, id: "form-#{changeset.data.tournament_id}-#{changeset.data.id}")
  end

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

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, put_flash(socket, :error, "Something wrong happened when creating a round")}
    end
  end

  @impl true
  def handle_event("add-participant", _, socket) do
    tournament_id = socket.assigns.tournament.id

    case Participants.create_empty_participant(tournament_id) do
      {:ok, participant} ->
        {:noreply,
         socket
         |> put_flash(:info, "Participant created successfully")
         |> reload_page()}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply,
         put_flash(socket, :error, "Something wrong happened when adding a participant")}
    end
  end

  @impl true
  def handle_event("delete-participant", %{"id" => id}, socket) do
    tournament_id = socket.assigns.tournament.id

    participant = Participants.get_participant!(id)
    {:ok, _} = Participants.delete_participant(participant)

    {:noreply, reload_page(socket)}
  end

  defp reload_page(socket) do
    socket |> push_navigate(to: ~p"/tournaments/#{socket.assigns.tournament.id}")
  end
end
