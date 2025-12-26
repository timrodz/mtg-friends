defmodule MtgFriendsWeb.API.ParticipantController do
  use MtgFriendsWeb, :controller

  alias MtgFriends.Participants
  alias MtgFriends.Participants.Participant

  action_fallback MtgFriendsWeb.FallbackController

  alias MtgFriends.Tournaments

  def create(conn, %{"tournament_id" => tournament_id, "participant" => participant_params}) do
    tournament = Tournaments.get_tournament_simple!(tournament_id)

    if tournament.user_id == conn.assigns.current_user.id do
      params = Map.put(participant_params, "tournament_id", tournament_id)

      with {:ok, %Participant{} = participant} <- Participants.create_participant(params) do
        conn
        |> put_status(:created)
        |> render(:show, participant: participant)
      end
    else
      {:error, :forbidden}
    end
  end

  def update(conn, %{"id" => id, "participant" => participant_params}) do
    participant = Participants.get_participant!(id)
    tournament = Tournaments.get_tournament_simple!(participant.tournament_id)

    if tournament.user_id == conn.assigns.current_user.id do
      with {:ok, %Participant{} = participant} <-
             Participants.update_participant(participant, participant_params) do
        render(conn, :show, participant: participant)
      end
    else
      {:error, :forbidden}
    end
  end

  def delete(conn, %{"id" => id}) do
    participant = Participants.get_participant!(id)
    tournament = Tournaments.get_tournament_simple!(participant.tournament_id)

    if tournament.user_id == conn.assigns.current_user.id do
      with {:ok, %Participant{}} <- Participants.delete_participant(participant) do
        send_resp(conn, :no_content, "")
      end
    else
      {:error, :forbidden}
    end
  end
end
