defmodule MtgFriendsWeb.TournamentLive.Show do
  use MtgFriendsWeb, :live_view

  alias MtgFriends.Tournaments
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

    participant_forms =
      Enum.map(
        tournament.participants,
        &build_participant_form(&1, %{tournament_id: tournament.id})
      )

    {
      :noreply,
      socket
      |> assign(:page_title, page_title(socket.assigns.live_action))
      |> assign(:tournament, tournament)
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

  defp build_empty_form(tournament_id) do
    build_participant_form(
      %Participant{tournament_id: tournament_id, name: "", points: 0, decklist: ""},
      %{}
    )
  end

  @impl true
  def handle_event("save-tournament", _, socket) do
    tournament_id = socket.assigns.tournament.id

    participant_change_params =
      Enum.filter(
        Enum.map(socket.assigns.participant_forms, fn form ->
          participant =
            Map.take(Map.from_struct(form.data), [:id, :name, :points, :decklist])

          if String.length(participant.name || "") == 0 and
               String.length(participant.decklist || "") == 0 do
            nil
          else
            Map.new(participant, fn {k, v} ->
              {Atom.to_string(k), if(is_nil(v), do: "", else: v)}
            end)
          end
        end),
        fn
          nil -> false
          _ -> true
        end
      )

    multi =
      Enum.reduce(participant_change_params, Ecto.Multi.new(), fn %{"id" => id} =
                                                                    participant_params,
                                                                  multi ->
        with participant <- Participants.get_participant!(id) do
          changeset =
            Participants.change_participant(participant, participant_params)
            |> IO.inspect(label: "participant #{id} changeset")

          Ecto.Multi.update(
            multi,
            "update_tournament_#{tournament_id}_participant_#{id}",
            changeset
          )
        end
      end)

    case MtgFriends.Repo.transaction(multi) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Tournament updated successfully")
         |> push_navigate(to: ~p"/tournaments/#{tournament_id}")}

      {:error, _, error, _} ->
        {:error, error}
    end
  end

  @impl true
  def handle_event("add-participant", _, socket) do
    tournament_id = socket.assigns.tournament.id

    case Participants.create_empty_participant(tournament_id) do
      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, put_flash(socket, :error, "Something wrong happened")}

      {:ok, participant} ->
        {:noreply, push_navigate(socket, to: ~p"/tournaments/#{tournament_id}")}
    end
  end

  @impl true
  def handle_event("delete-participant", %{"id" => id}, socket) do
    tournament_id = socket.assigns.tournament.id

    participant = Participants.get_participant!(id)
    {:ok, _} = Participants.delete_participant(participant)

    {:noreply, push_navigate(socket, to: ~p"/tournaments/#{tournament_id}")}
  end

  @impl true
  def handle_event(event, %{"id" => participant_id_str} = params, socket) do
    {changed_participant_id, ""} =
      Integer.parse(participant_id_str)

    # Loop over participants inside the forms
    updated_participants =
      socket.assigns.participant_forms
      |> Enum.map(fn participant ->
        Map.put(
          participant,
          :data,
          update_participant_metadata(
            changed_participant_id,
            participant.data,
            event,
            params
          )
        )
        # Just grab the data so we can create new forms
        |> Map.get(:data)
      end)

    participant_forms =
      Enum.map(
        updated_participants,
        &build_participant_form(&1, %{tournament_id: socket.assigns.tournament.id})
      )

    {:noreply, assign(socket, :participant_forms, participant_forms)}
  end

  defp update_participant_metadata(participant_to_update_id, participant, event, changes \\ nil) do
    with true <- participant.id == participant_to_update_id do
      case event do
        "add-points" ->
          Map.replace!(participant, :points, participant.points + 1)

        "decrease-points" ->
          Map.replace!(participant, :points, participant.points - 1)

        "update-decklist" ->
          Map.replace!(participant, :decklist, changes["participant"] |> Map.get("decklist"))

        "update-name" ->
          Map.replace!(participant, :name, changes["participant"] |> Map.get("name"))
      end
    else
      _ ->
        participant
    end
  end
end
