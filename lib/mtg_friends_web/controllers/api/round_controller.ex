defmodule MtgFriendsWeb.API.RoundController do
  use MtgFriendsWeb, :controller

  use OpenApiSpex.ControllerSpecs

  alias MtgFriends.Rounds
  alias MtgFriends.Rounds.Round
  alias MtgFriendsWeb.Schemas

  action_fallback MtgFriendsWeb.FallbackController

  tags ["rounds"]

  operation :index,
    summary: "List rounds for tournament",
    security: [],
    parameters: [
      tournament_id: [in: :path, description: "Tournament ID", type: :integer, example: 1]
    ],
    responses: [
      ok: {"Rounds list", "application/json", Schemas.RoundsResponse}
    ]

  operation :show,
    summary: "Show round",
    security: [],
    parameters: [
      tournament_id: [in: :path, description: "Tournament ID", type: :integer, example: 1],
      id: [in: :path, description: "Round ID", type: :integer, example: 1]
    ],
    responses: [
      ok: {"Round details", "application/json", Schemas.RoundResponse},
      not_found: {"Round not found", "application/json", Schemas.ErrorResponse}
    ]

  operation :create,
    summary: "Create round",
    security: [%{"authorization" => []}],
    parameters: [
      tournament_id: [in: :path, description: "Tournament ID", type: :integer]
    ],
    request_body: {"Round params", "application/json", Schemas.RoundRequest},
    responses: [
      created: {"Round created", "application/json", Schemas.RoundResponse},
      conflict:
        {"Round creation failed (latest round not complete)", "application/json",
         Schemas.ErrorResponse},
      unprocessable_entity: {"Validation error", "application/json", Schemas.ErrorResponse}
    ]

  operation :update,
    summary: "Update round",
    security: [%{"authorization" => []}],
    parameters: [
      tournament_id: [in: :path, description: "Tournament ID", type: :integer],
      id: [in: :path, description: "Round ID", type: :integer]
    ],
    request_body: {"Round params", "application/json", Schemas.RoundRequest},
    responses: [
      ok: {"Round results updated", "application/json", Schemas.RoundResponse},
      unprocessable_entity: {"Validation error", "application/json", Schemas.ErrorResponse}
    ]

  operation :delete,
    summary: "Remove round",
    security: [%{"authorization" => []}],
    parameters: [
      tournament_id: [in: :path, description: "Tournament ID", type: :integer],
      id: [in: :path, description: "Round ID", type: :integer]
    ],
    responses: [
      no_content: "Round removed",
      not_found: {"Round not found", "application/json", Schemas.ErrorResponse}
    ]

  def index(conn, %{"tournament_id" => tournament_id}) do
    rounds =
      Rounds.list_rounds(tournament_id)
      # Preload pairings as they are part of the RoundJSON view
      |> MtgFriends.Repo.preload(pairings: [pairing_participants: :participant])

    render(conn, :index, rounds: rounds)
  end

  def show(conn, %{"tournament_id" => _tournament_id, "id" => id}) do
    round =
      Rounds.get_round!(id)
      |> MtgFriends.Repo.preload(pairings: [pairing_participants: :participant])

    conn
    |> render(:show, round: round)
  end

  def create(conn, %{"tournament_id" => tournament_id} = round_params) do
    with {:ok, round} <-
           Rounds.create_round(round_params |> Map.put("tournament_id", tournament_id)) do
      round = MtgFriends.Repo.preload(round, pairings: :pairing_participants)

      conn
      |> put_status(:created)
      |> render(:show, round: round)
    end
  end

  def update(
        conn,
        %{
          "tournament_id" => _tournament_id,
          "id" => id
        } = round_params
      ) do
    round = Rounds.get_round!(id)

    with {:ok, updated_round} <- Rounds.update_round(round, round_params) do
      updated_round = MtgFriends.Repo.preload(updated_round, pairings: :pairing_participants)

      conn
      |> put_status(:ok)
      |> render(:show, round: updated_round)
    end
  end

  def delete(conn, %{
        "tournament_id" => _tournament_id,
        "id" => id
      }) do
    round = Rounds.get_round!(id)

    with {:ok, %Round{}} <- Rounds.delete_round(round) do
      send_resp(conn, :no_content, "")
    end
  end
end
