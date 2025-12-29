defmodule MtgFriendsWeb.API.RoundController do
  use MtgFriendsWeb, :controller

  use OpenApiSpex.ControllerSpecs

  alias MtgFriends.Rounds
  alias MtgFriends.Rounds.Round
  alias MtgFriendsWeb.Schemas

  action_fallback MtgFriendsWeb.FallbackController

  tags ["rounds"]

  operation :show,
    summary: "Show round",
    security: [],
    parameters: [
      tournament_id: [in: :path, description: "Tournament ID", type: :integer, example: 1],
      number: [in: :path, description: "Round number", type: :integer, example: 1]
    ],
    responses: [
      ok: {"Round details", "application/json", Schemas.RoundResponse},
      not_found: {"Round not found", "application/json", Schemas.ErrorResponse}
    ]

  operation :create,
    summary: "Create next round",
    security: [%{"authorization" => []}],
    parameters: [
      tournament_id: [in: :path, description: "Tournament ID", type: :integer]
    ],
    responses: [
      created: {"Round created", "application/json", Schemas.RoundResponse},
      conflict:
        {"Round creation failed (latest round not complete)", "application/json",
         Schemas.ErrorResponse},
      unprocessable_entity: {"Validation error", "application/json", Schemas.ErrorResponse}
    ]

  operation :update,
    summary: "Update round results",
    security: [%{"authorization" => []}],
    parameters: [
      tournament_id: [in: :path, description: "Tournament ID", type: :integer],
      number: [in: :path, description: "Round number", type: :integer]
    ],
    request_body: {"Round results", "application/json", Schemas.RoundResultsRequest},
    responses: [
      ok: {"Round results updated", "application/json", Schemas.RoundResponse},
      unprocessable_entity: {"Validation error", "application/json", Schemas.ErrorResponse}
    ]

  def show(conn, %{"tournament_id" => tournament_id, "number" => number_str}) do
    {number, _} = Integer.parse(number_str)
    round = Rounds.get_round_by_tournament_and_round_number!(tournament_id, number, true)
    render(conn, :show, round: round)
  end

  alias MtgFriends.PairingEngine

  def create(conn, %{"tournament_id" => tournament_id}) do
    # Reload tournament with preloads required for logic and PairingEngine
    tournament = MtgFriends.Tournaments.get_tournament!(tournament_id)

    # Check if latest round is complete
    latest_round = List.last(tournament.rounds)

    if latest_round && !Rounds.is_round_complete?(Rounds.get_round!(latest_round.id, true)) do
      {:error, :conflict}
    else
      current_round_count = Enum.count(tournament.rounds)

      with {:ok, %Round{} = round} <-
             Rounds.create_round_for_tournament(tournament_id, current_round_count) do
        # Refresh tournament with preloads required by PairingEngine
        tournament = MtgFriends.Tournaments.get_tournament!(tournament_id)

        case PairingEngine.create_pairings(tournament, round) do
          {:ok, _pairings} ->
            :ok

          {:error, reason} ->
            # Consider rolling back the round creation or returning an error
            raise "Failed to create pairings: #{inspect(reason)}"
        end

        # Re-fetch round with pairings to render
        round = Rounds.get_round!(round.id, true)

        conn
        |> put_status(:created)
        |> render(:show, round: round)
      end
    end
  end

  alias MtgFriends.Pairings

  def update(conn, %{
        "tournament_id" => tournament_id,
        "number" => number_str,
        "results" => results
      }) do
    {number, _} = Integer.parse(number_str)
    # Get round ID from number
    round = Rounds.get_round_by_tournament_and_round_number!(tournament_id, number)
    tournament = conn.assigns.tournament

    # Transform results to form params expected by update_pairings
    # update_pairings expects: %{"input-points-participant-ID" => "POINTS", ...}

    form_params =
      Enum.reduce(results, %{}, fn %{"participant_id" => pid, "points" => points}, acc ->
        Map.put(acc, "input-points-participant-#{pid}", "#{points}")
      end)

    with {:ok, _} <- Pairings.update_pairings(tournament_id, round.id, form_params) do
      # Check if round is complete and update status
      # Refresh pairings
      round = Rounds.get_round!(round.id)
      {:ok, round, _status} = Rounds.check_and_finalize(round, tournament)

      render(conn, :show, round: round)
    end
  end
end
