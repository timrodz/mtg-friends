defmodule MtgFriendsWeb.API.TournamentController do
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

  operation :create,
    summary: "Create tournament",
    security: [%{"authorization" => []}],
    request_body: {"Tournament params", "application/json", Schemas.TournamentRequest},
    responses: [
      created: {"Tournament created", "application/json", Schemas.TournamentResponse},
      unprocessable_entity: {"Validation error", "application/json", Schemas.ErrorResponse}
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

  def create(conn, %{"tournament" => tournament_params}) do
    initial_participants =
      Map.get(tournament_params, "initial_participants", "")
      |> String.split("\n", trim: true)

    result =
      MtgFriends.Repo.transaction(fn ->
        with {:ok, tournament} <- Tournaments.create_tournament(tournament_params),
             {:ok, _} <-
               MtgFriends.Participants.create_x_participants(tournament.id, initial_participants) do
          tournament
        else
          {:error, %Ecto.Changeset{} = changeset} -> MtgFriends.Repo.rollback(changeset)
          {:error, _name, changeset, _changes} -> MtgFriends.Repo.rollback(changeset)
        end
      end)

    case result do
      {:ok, tournament} ->
        conn
        |> put_status(:created)
        |> put_resp_header("location", ~p"/api/tournaments/#{tournament}")
        |> render(:show, tournament: tournament)

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  def show(conn, %{"id" => id}) do
    tournament = Tournaments.get_tournament!(id)
    render(conn, :show, tournament: tournament)
  end

  def update(conn, %{"tournament" => tournament_params}) do
    tournament = conn.assigns.tournament

    with {:ok, %Tournament{} = tournament} <-
           Tournaments.update_tournament(tournament, tournament_params) do
      render(conn, :show, tournament: tournament)
    end
  end
end
