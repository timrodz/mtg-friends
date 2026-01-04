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
  def get_overall_scores(participants) do
    participants
    |> Enum.map(fn participant ->
      %{
        id: participant.id,
        total_score: participant.points || 0,
        win_rate: Decimal.from_float(participant.win_rate || 0.0)
      }
    end)
    # Sort by total score (desc) and then win rate (desc)
    |> Enum.sort_by(&{&1.total_score, &1.win_rate}, :desc)
  end
end
