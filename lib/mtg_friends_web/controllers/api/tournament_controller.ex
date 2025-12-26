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
    initial_participants =
      Map.get(tournament_params, "initial_participants", "")
      |> String.split("\n", trim: true)

    result =
      MtgFriends.Repo.transaction(fn ->
        with {:ok, tournament} <- Tournaments.create_tournament(tournament_params),
             {:ok, _} <- MtgFriends.Participants.create_x_participants(tournament.id, initial_participants) do
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

    with {:ok, %Tournament{} = tournament} <- Tournaments.update_tournament(tournament, tournament_params) do
      render(conn, :show, tournament: tournament)
    end
  end
end
