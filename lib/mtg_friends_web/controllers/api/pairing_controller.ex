defmodule MtgFriendsWeb.API.PairingController do
  use MtgFriendsWeb, :controller
  use OpenApiSpex.ControllerSpecs

  alias MtgFriends.Pairings.Pairing
  alias MtgFriends.Pairings
  alias MtgFriendsWeb.Schemas

  action_fallback MtgFriendsWeb.FallbackController

  tags ["pairings"]

  operation :index,
    summary: "List pairings for tournament",
    security: [],
    parameters: [
      tournament_id: [in: :path, description: "Tournament ID", type: :integer, example: 1],
      round_id: [in: :path, description: "Round ID", type: :integer, example: 1]
    ],
    responses: [
      ok: {"Pairings list", "application/json", Schemas.PairingsResponse}
    ]

  operation :show,
    summary: "Show pairing",
    security: [],
    parameters: [
      tournament_id: [in: :path, description: "Tournament ID", type: :integer, example: 1],
      id: [in: :path, description: "Pairing ID", type: :integer, example: 1]
    ],
    responses: [
      ok: {"Pairing details", "application/json", Schemas.PairingResponse},
      not_found: {"Pairing not found", "application/json", Schemas.ErrorResponse}
    ]

  operation :create,
    summary: "Create pairing",
    security: [%{"authorization" => []}],
    parameters: [
      tournament_id: [in: :path, description: "Tournament ID", type: :integer]
    ],
    request_body: {"Pairing params", "application/json", Schemas.PairingRequest},
    responses: [
      created: {"Pairing created", "application/json", Schemas.PairingResponse},
      conflict:
        {"Pairing creation failed (latest pairing not complete)", "application/json",
         Schemas.ErrorResponse},
      unprocessable_entity: {"Validation error", "application/json", Schemas.ErrorResponse}
    ]

  operation :update,
    summary: "Update pairing",
    security: [%{"authorization" => []}],
    parameters: [
      tournament_id: [in: :path, description: "Tournament ID", type: :integer],
      id: [in: :path, description: "Pairing ID", type: :integer]
    ],
    request_body: {"Pairing params", "application/json", Schemas.PairingRequest},
    responses: [
      ok: {"Pairing results updated", "application/json", Schemas.PairingResponse},
      unprocessable_entity: {"Validation error", "application/json", Schemas.ErrorResponse}
    ]

  operation :delete,
    summary: "Remove pairing",
    security: [%{"authorization" => []}],
    parameters: [
      tournament_id: [in: :path, description: "Tournament ID", type: :integer],
      id: [in: :path, description: "Pairing ID", type: :integer]
    ],
    responses: [
      no_content: "Pairing removed",
      not_found: {"Pairing not found", "application/json", Schemas.ErrorResponse}
    ]

  def index(conn, %{"tournament_id" => tournament_id, "round_id" => round_id}) do
    pairings = Pairings.list_pairings(tournament_id, round_id)
    render(conn, :index, pairings: pairings)
  end

  def show(conn, %{"tournament_id" => _tournament_id, "id" => id}) do
    pairing = Pairings.get_pairing!(id)
    render(conn, :show, pairing: pairing)
  end

  def create(conn, %{"tournament_id" => tournament_id} = pairing_params) do
    with {:ok, pairing} <-
           Pairings.create_pairing(pairing_params |> Map.put("tournament_id", tournament_id)) do
      conn
      |> put_status(:created)
      |> render(:show, pairing: pairing)
    end
  end

  def update(conn, %{"tournament_id" => _tournament_id, "id" => id} = pairing_params) do
    pairing = Pairings.get_pairing!(id)

    with {:ok, updated_pairing} <- Pairings.update_pairing(pairing, pairing_params) do
      conn
      |> put_status(:ok)
      |> render(:show, pairing: updated_pairing)
    end
  end

  def delete(conn, %{
        "tournament_id" => _tournament_id,
        "id" => id
      }) do
    pairing = Pairings.get_pairing!(id)

    with {:ok, %Pairing{}} <- Pairings.delete_pairing(pairing) do
      send_resp(conn, :no_content, "")
    end
  end
end
