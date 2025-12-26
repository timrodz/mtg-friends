defmodule MtgFriendsWeb.API.TournamentController do
  use MtgFriendsWeb, :controller

  alias MtgFriends.Tournaments
  alias MtgFriends.Tournaments.Tournament

  action_fallback MtgFriendsWeb.FallbackController

  def index(conn, params) do
    page = Map.get(params, "page", "1") |> String.to_integer()
    limit = Map.get(params, "limit", "10") |> String.to_integer()

    tournaments = Tournaments.list_tournaments_paginated(limit, page)
    render(conn, :index, tournaments: tournaments)
  end

  def create(conn, %{"tournament" => tournament_params}) do
    with {:ok, %Tournament{} = tournament} <- Tournaments.create_tournament(tournament_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", ~p"/api/tournaments/#{tournament}")
      |> render(:show, tournament: tournament)
    end
  end

  def show(conn, %{"id" => id}) do
    tournament = Tournaments.get_tournament!(id)
    render(conn, :show, tournament: tournament)
  end

  def update(conn, %{"id" => id, "tournament" => tournament_params}) do
    tournament = Tournaments.get_tournament!(id)

    if tournament.user_id == conn.assigns.current_user.id do
      with {:ok, %Tournament{} = tournament} <- Tournaments.update_tournament(tournament, tournament_params) do
        render(conn, :show, tournament: tournament)
      end
    else
      conn
      |> put_status(:forbidden)
      |> json(%{error: "You are not authorized to edit this tournament"})
    end
  end
end
