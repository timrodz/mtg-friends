defmodule MtgFriendsWeb.API.ParticipantController do
  use MtgFriendsWeb, :controller

  use OpenApiSpex.ControllerSpecs

  alias MtgFriends.Participants
  alias MtgFriends.Participants.Participant
  alias MtgFriendsWeb.Schemas

  action_fallback MtgFriendsWeb.FallbackController

  tags ["participants"]

  operation :show,
    summary: "Show participant",
    security: [],
    parameters: [
      tournament_id: [in: :path, description: "Tournament ID", type: :integer, example: 1],
      id: [in: :path, description: "Participant ID", type: :integer, example: 1]
    ],
    responses: [
      ok: {"Participant details", "application/json", Schemas.ParticipantResponse},
      not_found: {"Participant not found", "application/json", Schemas.ErrorResponse}
    ]

  operation :create,
    summary: "Create participant",
    security: [%{"authorization" => []}],
    parameters: [
      tournament_id: [in: :path, description: "Tournament ID", type: :integer]
    ],
    request_body: {"Participant params", "application/json", Schemas.ParticipantRequest},
    responses: [
      created: {"Participant created", "application/json", Schemas.ParticipantResponse},
      conflict:
        {"Participant creation failed (latest participant not complete)", "application/json",
         Schemas.ErrorResponse},
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
      ok: {"Participant results updated", "application/json", Schemas.ParticipantResponse},
      unprocessable_entity: {"Validation error", "application/json", Schemas.ErrorResponse}
    ]

  operation :delete,
    summary: "Remove participant",
    security: [%{"authorization" => []}],
    parameters: [
      tournament_id: [in: :path, description: "Tournament ID", type: :integer],
      id: [in: :path, description: "Participant ID", type: :integer]
    ],
    responses: [
      no_content: "Participant removed",
      not_found: {"Participant not found", "application/json", Schemas.ErrorResponse}
    ]

  def show(conn, %{"tournament_id" => _tournament_id, "id" => id}) do
    participant = Participants.get_participant!(id)
    render(conn, :show, participant: participant)
  end

  def create(conn, %{"tournament_id" => tournament_id} = participant_params) do
    with {:ok, participant} <-
           Participants.create_participant(
             participant_params
             |> Map.put("tournament_id", tournament_id)
           ) do
      conn
      |> put_status(:created)
      |> render(:show, participant: participant)
    end
  end

  def update(
        conn,
        %{
          "tournament_id" => _tournament_id,
          "id" => id
        } = participant_params
      ) do
    participant = Participants.get_participant!(id)

    with {:ok, %Participant{} = participant} <-
           Participants.update_participant(participant, participant_params) do
      conn
      |> put_status(:ok)
      |> render(:show, participant: participant)
    end
  end

  def delete(conn, %{"tournament_id" => _tournament_id, "id" => id}) do
    participant = Participants.get_participant!(id)

    with {:ok, %Participant{}} <- Participants.delete_participant(participant) do
      send_resp(conn, :no_content, "")
    end
  end
end
