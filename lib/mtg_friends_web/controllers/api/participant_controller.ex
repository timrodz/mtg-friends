defmodule MtgFriendsWeb.API.ParticipantController do
  use MtgFriendsWeb, :controller

  use OpenApiSpex.ControllerSpecs

  alias MtgFriends.Participants
  alias MtgFriends.Participants.Participant
  alias MtgFriendsWeb.Schemas

  action_fallback MtgFriendsWeb.FallbackController

  tags ["participants"]

  operation :create,
    summary: "Add participant to tournament",
    security: [%{"authorization" => []}],
    parameters: [
      tournament_id: [in: :path, description: "Tournament ID", type: :integer, example: 1]
    ],
    request_body: {"Participant params", "application/json", Schemas.ParticipantRequest},
    responses: [
      created: {"Participant created", "application/json", Schemas.ParticipantResponse},
      unprocessable_entity: {"Validation error", "application/json", Schemas.ErrorResponse}
    ]

  operation :update,
    summary: "Update participant",
    security: [%{"authorization" => []}],
    parameters: [
      tournament_id: [in: :path, description: "Tournament ID", type: :integer],
      id: [in: :path, description: "Participant ID", type: :integer]
    ],
    request_body: {"Participant params", "application/json", Schemas.ParticipantRequest},
    responses: [
      ok: {"Participant updated", "application/json", Schemas.ParticipantResponse},
      unprocessable_entity: {"Validation error", "application/json", Schemas.ErrorResponse}
    ]

  operation :delete,
    summary: "Remove participant from tournament",
    security: [%{"authorization" => []}],
    parameters: [
      tournament_id: [in: :path, description: "Tournament ID", type: :integer],
      id: [in: :path, description: "Participant ID", type: :integer]
    ],
    responses: [
      no_content: "Participant removed",
      not_found: {"Participant not found", "application/json", Schemas.ErrorResponse}
    ]

  def create(conn, %{"tournament_id" => tournament_id, "participant" => participant_params}) do
    params = Map.put(participant_params, "tournament_id", tournament_id)

    with {:ok, %Participant{} = participant} <- Participants.create_participant(params) do
      conn
      |> put_status(:created)
      |> render(:show, participant: participant)
    end
  end

  def update(conn, %{"id" => id, "participant" => participant_params}) do
    participant = Participants.get_participant!(id)

    with {:ok, %Participant{} = participant} <-
           Participants.update_participant(participant, participant_params) do
      render(conn, :show, participant: participant)
    end
  end

  def delete(conn, %{"id" => id}) do
    participant = Participants.get_participant!(id)

    with {:ok, %Participant{}} <- Participants.delete_participant(participant) do
      send_resp(conn, :no_content, "")
    end
  end
end
