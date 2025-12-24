defmodule MtgFriendsWeb.API.RoundController do
  use MtgFriendsWeb, :controller

  alias MtgFriends.Rounds
  alias MtgFriends.Rounds.Round

  action_fallback MtgFriendsWeb.FallbackController

  def show(conn, %{"tournament_id" => tournament_id, "number" => number}) do
    round = Rounds.get_round_by_tournament_and_round_number!(tournament_id, number, true)
    render(conn, :show, round: round)
  end

  alias MtgFriends.PairingEngine

  def create(conn, %{"tournament_id" => tournament_id}) do
    tournament = MtgFriends.Tournaments.get_tournament!(tournament_id)

    current_round_count = Enum.count(tournament.rounds)

    with {:ok, %Round{} = round} <- Rounds.create_round_for_tournament(tournament_id, current_round_count) do
      # Refresh tournament with preloads required by PairingEngine
      tournament = MtgFriends.Tournaments.get_tournament!(tournament_id)

      PairingEngine.create_pairings(tournament, round)

      # Re-fetch round with pairings to render
      round = Rounds.get_round!(round.id, true)

      conn
      |> put_status(:created)
      |> render(:show, round: round)
    end
  end
end
