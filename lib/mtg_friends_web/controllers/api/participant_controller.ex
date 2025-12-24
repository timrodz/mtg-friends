defmodule MtgFriendsWeb.API.ParticipantController do
  use MtgFriendsWeb, :controller

  alias MtgFriends.Participants
  alias MtgFriends.Participants.Participant

  action_fallback MtgFriendsWeb.FallbackController

  def create(conn, %{"tournament_id" => tournament_id, "participant" => participant_params}) do
    params = Map.put(participant_params, "tournament_id", tournament_id)

    with {:ok, %Participant{} = participant} <- Participants.create_participant(params) do
      conn
      |> put_status(:created)
      |> render(:show, participant: participant)
    end
  end

  def delete(conn, %{"id" => id}) do
    participant = Participants.get_participant!(id)

    with {:ok, %Participant{}} <- Participants.delete_participant(participant) do
      send_resp(conn, :no_content, "")
    end
  end
end
