defmodule MtgFriendsWeb.API.TournamentController do
  require Logger

  use MtgFriendsWeb, :controller
  use OpenApiSpex.ControllerSpecs

  alias MtgFriends.Tournaments
  alias MtgFriends.Tournaments.Tournament
  alias MtgFriendsWeb.Schemas

  action_fallback MtgFriendsWeb.FallbackController

  tags ["tournaments"]

  operation :index,
    summary: "List tournaments",
    security: [],
    parameters: [
      page: [in: :query, description: "Page number", type: :integer],
      limit: [in: :query, description: "Items per page", type: :integer]
    ],
    responses: [
      ok: {"Tournaments list", "application/json", Schemas.TournamentsResponse}
    ]

  operation :show,
    summary: "Show tournament",
    security: [],
    parameters: [
      id: [in: :path, description: "Tournament ID", type: :integer, example: 1]
    ],
    responses: [
      ok: {"Tournament details", "application/json", Schemas.TournamentResponse},
      not_found: {"Tournament not found", "application/json", Schemas.ErrorResponse}
    ]

  operation :create,
    summary: "Create tournament",
    security: [%{"authorization" => []}],
    request_body: {"Tournament params", "application/json", Schemas.TournamentRequest},
    responses: [
      ok: {"Tournament created", "application/json", Schemas.TournamentResponse},
      unprocessable_entity: {"Validation error", "application/json", Schemas.ErrorResponse}
    ]

  operation :update,
    summary: "Update tournament",
    security: [%{"authorization" => []}],
    parameters: [
      tournament_id: [in: :path, description: "Tournament ID", type: :integer]
    ],
    request_body: {"Tournament params", "application/json", Schemas.TournamentRequest},
    responses: [
      ok: {"Tournament updated", "application/json", Schemas.TournamentResponse},
      unprocessable_entity: {"Validation error", "application/json", Schemas.ErrorResponse}
    ]

  operation :delete,
    summary: "Remove tournament",
    security: [%{"authorization" => []}],
    parameters: [
      tournament_id: [in: :path, description: "Tournament ID", type: :integer]
    ],
    responses: [
      no_content: "Tournament removed",
      not_found: {"Tournament not found", "application/json", Schemas.ErrorResponse}
    ]

  def index(conn, params) do
    page =
      case Integer.parse(Map.get(params, "page", "1")) do
        {page, _} -> page
        _ -> 1
      end

    limit =
      case Integer.parse(Map.get(params, "limit", "10")) do
        {limit, _} -> limit
        _ -> 10
      end

    tournaments = Tournaments.list_tournaments_paginated(limit, page)
    render(conn, :index, tournaments: tournaments)
  end

  def show(conn, %{"id" => id}) do
    tournament = Tournaments.get_tournament!(id)
    render(conn, :show, tournament: tournament)
  end

  def create(conn, tournament_params) do
    with {:ok, %Tournament{} = tournament} <- Tournaments.create_tournament(tournament_params) do
      conn
      |> put_status(:created)
      |> render(:show, tournament: tournament)
    end
  end

  def update(conn, %{"tournament_id" => id} = tournament_params) do
    tournament = Tournaments.get_tournament!(id)

    with {:ok, %Tournament{} = tournament} <-
           Tournaments.update_tournament(tournament, tournament_params) do
      render(conn, :show, tournament: tournament)
    end
  end

  def delete(conn, %{"tournament_id" => id}) do
    tournament = Tournaments.get_tournament!(id)

    with {:ok, %Tournament{}} <- Tournaments.delete_tournament(tournament) do
      send_resp(conn, :no_content, "")
    end
  end
end
