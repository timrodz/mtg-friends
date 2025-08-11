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
  def get_overall_scores(rounds, num_pairings) do
    rounds
    |> Enum.flat_map(fn round -> round.pairings end)
    |> Enum.group_by(&Map.get(&1, :participant_id))
    |> Enum.map(fn {id, pairings} ->
      total_score =
        Enum.reduce(pairings, 0, fn cur_pairing, acc ->
          calculate_participant_round_score(rounds, num_pairings, cur_pairing, acc)
        end)
        |> Decimal.from_float()
        |> Decimal.round(3)

      total_wins =
        Enum.reduce(pairings, 0, fn pairing, acc -> 
          (pairing.winner && 1 + acc) || acc 
        end)

      %{
        id: id,
        total_score: total_score,
        win_rate: (total_wins / length(rounds) * 100) |> Decimal.from_float()
      }
    end)
    |> Enum.sort_by(&{&1.total_score, &1.win_rate}, :desc)
  end

  # Private function to calculate a participant's score for a specific round
  defp calculate_participant_round_score(rounds, num_pairings, cur_pairing, acc) do
    cur_round = Enum.find(rounds, fn r -> r.id == cur_pairing.round_id end)

    # Convert to float for consistent calculations
    if cur_round.status == :active do
      cur_pairing.points + 0.0 + acc
    else
      case cur_round.number do
        0 ->
          cur_pairing.points + 0.0 + acc

        _ ->
          {decimals, ""} =
            Float.parse("0.00#{abs(num_pairings - cur_pairing.number)}")

          cur_pairing.points + decimals + acc
      end
    end
  end
end