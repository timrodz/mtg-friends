defmodule MtgFriends.TournamentUtils do
  @moduledoc """
  Core tournament utilities and scoring functions.

  This module has been refactored to focus on core business logic,
  with rendering moved to TournamentRenderer and pairing algorithms
  moved to PairingEngine.
  """

  require Logger
  alias MtgFriends.PairingEngine

  @doc """
  Creates pairings for a tournament round using the appropriate algorithm.
  Delegates to PairingEngine for the actual pairing logic.
  """
  def create_pairings(tournament, round) do
    PairingEngine.create_pairings(tournament, round)
  end

  @doc """
  Calculates the number of pairings needed based on participant count and format.
  Delegates to PairingEngine for consistency.
  """
  def get_num_pairings(participant_count, format) do
    PairingEngine.calculate_num_pairings(participant_count, format)
  end

  @doc """
  Calculates overall scores for all participants across tournament rounds.

  Returns a list of participant score maps sorted by total score and win rate.
  """
  def get_overall_scores(rounds) do
    rounds
    # 1. Extract all pairings from all rounds
    |> Enum.flat_map(fn round ->
      Enum.map(round.pairings, fn pairing ->
        {pairing, pairing.pairing_participants}
      end)
    end)
    # 2. Transform into a list of individual participant results for each pairing
    |> Enum.flat_map(fn {pairing, participants} ->
      Enum.map(participants, fn participant ->
        # Check against pairing winner_id if available.
        # It assumes pairing.winner_id is the ID of the PairingParticipant that won.
        is_winner = pairing.winner_id == participant.id

        %{
          participant_id: participant.participant_id,
          points: participant.points || 0,
          is_winner: is_winner
        }
      end)
    end)
    # 3. Group results by participant
    |> Enum.group_by(& &1.participant_id)
    # 4. Aggregate scores and calculate win rates
    |> Enum.map(fn {participant_id, stats} ->
      total_score =
        stats
        |> Enum.map(& &1.points)
        |> Enum.sum()

      total_wins = Enum.count(stats, & &1.is_winner)

      # Avoid division by zero if rounds is empty, though flat_map would produce empty stats anyway
      round_count = max(length(rounds), 1)
      win_rate = total_wins / round_count * 100

      %{
        id: participant_id,
        total_score: total_score,
        win_rate: Decimal.from_float(win_rate)
      }
    end)
    # 5. Sort by total score (desc) and then win rate (desc)
    |> Enum.sort_by(&{&1.total_score, &1.win_rate}, :desc)
  end
end
