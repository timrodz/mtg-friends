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

  def create(conn, %{"tournament_id" => tournament_id, "round_id" => round_id} = pairing_params) do
    # Compatibility with legacy single-participant params or simplified testing
    pairing_params =
      if Map.has_key?(pairing_params, "participant_id") and
           not Map.has_key?(pairing_params, "pairing_participants") do
        Map.put(pairing_params, "pairing_participants", [
          %{
            "participant_id" => pairing_params["participant_id"],
            "points" => pairing_params["points"] || 0
          }
        ])
      else
        pairing_params
      end

    with {:ok, pairing} <-
           Pairings.create_pairing(
             pairing_params
             |> Map.put("tournament_id", tournament_id)
             |> Map.put("round_id", round_id)
           ) do
      pairing = MtgFriends.Repo.preload(pairing, :pairing_participants)

      conn
      |> put_status(:created)
      |> render(:show, pairing: pairing)
    end
  end

  def update(conn, %{"tournament_id" => _tournament_id, "id" => id} = pairing_params) do
    pairing = Pairings.get_pairing!(id) |> MtgFriends.Repo.preload(:pairing_participants)

    # Legacy support: if points/winner passed at top level and pairing has one participant
    pairing_params =
      if (Map.has_key?(pairing_params, "points") or Map.has_key?(pairing_params, "winner")) and
           not Map.has_key?(pairing_params, "pairing_participants") and
           length(pairing.pairing_participants) == 1 do
        [pp] = pairing.pairing_participants

        Map.put(pairing_params, "pairing_participants", [
          %{
            "id" => pp.id,
            "points" => pairing_params["points"] || pp.points,
            "participant_id" => pp.participant_id
          }
        ])
      else
        pairing_params
      end

    # Legacy support: winner (boolean) -> winner_id
    pairing_params =
      if Map.has_key?(pairing_params, "winner") and is_boolean(pairing_params["winner"]) and
           not Map.has_key?(pairing_params, "winner_id") and
           length(pairing.pairing_participants) == 1 do
        [pp] = pairing.pairing_participants

        if pairing_params["winner"] do
          Map.put(pairing_params, "winner_id", pp.id)
        else
          pairing_params
        end
      else
        pairing_params
      end

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
