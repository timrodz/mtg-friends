defmodule MtgFriendsWeb.API.RoundController do
  use MtgFriendsWeb, :controller

  alias MtgFriends.Rounds
  alias MtgFriends.Rounds.Round

  action_fallback MtgFriendsWeb.FallbackController

  def show(conn, %{"tournament_id" => tournament_id, "number" => number_str}) do
    {number, _} = Integer.parse(number_str)
    round = Rounds.get_round_by_tournament_and_round_number!(tournament_id, number, true)
    render(conn, :show, round: round)
  end

  alias MtgFriends.PairingEngine

  def create(conn, %{"tournament_id" => tournament_id}) do
    tournament = MtgFriends.Tournaments.get_tournament!(tournament_id)

    if tournament.user_id == conn.assigns.current_user.id do
      # Check if latest round is complete
      latest_round = List.last(tournament.rounds)

      if latest_round && !Rounds.is_round_complete?(Rounds.get_round!(latest_round.id, true)) do
        conn
        |> put_status(:conflict)
        |> json(%{error: "Current round is not complete"})
      else
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
    else
      send_resp(conn, :forbidden, "")
    end
  end

  alias MtgFriends.Pairings

  def update(conn, %{"tournament_id" => tournament_id, "number" => number_str, "results" => results}) do
    {number, _} = Integer.parse(number_str)
    # Get round ID from number
    round = Rounds.get_round_by_tournament_and_round_number!(tournament_id, number)
    tournament = MtgFriends.Tournaments.get_tournament_simple!(tournament_id)

    if tournament.user_id == conn.assigns.current_user.id do
       # Transform results to form params expected by update_pairings
       # update_pairings expects: %{"input-points-participant-ID" => "POINTS", ...}

       form_params =
         Enum.reduce(results, %{}, fn %{"participant_id" => pid, "points" => points}, acc ->
           Map.put(acc, "input-points-participant-#{pid}", "#{points}")
         end)

       with {:ok, _} <- Pairings.update_pairings(tournament_id, round.id, form_params) do
         # Check if round is complete and update status
         round = Rounds.get_round!(round.id) # Refresh pairings
         {:ok, round, _status} = Rounds.check_and_finalize(round, tournament)

         render(conn, :show, round: round)
       end
    else
      send_resp(conn, :forbidden, "")
    end
  end
end
