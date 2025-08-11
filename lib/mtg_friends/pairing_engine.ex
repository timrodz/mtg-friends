defmodule MtgFriends.PairingEngine do
  @moduledoc """
  Handles complex tournament pairing algorithms.
  
  This module contains all the pairing logic that was previously in TournamentUtils,
  providing a clean separation of concerns for tournament pairing strategies.
  """

  require Logger
  alias MtgFriends.{Rounds, Pairings}

  # Configuration constants
  @max_swiss_retries 12
  @edh_players_per_pod 4
  @edh_min_players_per_pod 3
  @standard_players_per_pairing 2

  @doc """
  Creates pairings for a tournament round using the appropriate algorithm.
  """
  def create_pairings(tournament, round) do
    active_participants = Enum.filter(tournament.participants, fn p -> not p.is_dropped end)
    tournament_format = tournament.format
    num_pairings = calculate_num_pairings(length(active_participants), tournament_format)
    is_last_round? = tournament.round_count == round.number + 1
    is_top_cut_4? = is_last_round? && tournament.is_top_cut_4

    participant_pairings =
      if is_top_cut_4? do
        create_top_cut_pairings(tournament, round, num_pairings)
      else
        create_regular_pairings(tournament, round, active_participants, num_pairings)
      end

    Pairings.create_multiple_pairings(participant_pairings)
  end

  @doc """
  Calculates the number of pairings needed based on participant count and format.
  """
  def calculate_num_pairings(participant_count, format) do
    case format do
      :edh ->
        round(Float.ceil(participant_count / @edh_players_per_pod))

      :standard ->
        round(Float.ceil(participant_count / @standard_players_per_pairing))
    end
  end

  # Private functions

  defp create_top_cut_pairings(tournament, round, num_pairings) do
    # Import scoring functions - we'll need to refactor this later
    import MtgFriends.TournamentUtils, only: [get_overall_scores: 2]
    
    get_overall_scores(tournament.rounds, num_pairings)
    |> Enum.take(4)
    |> Enum.map(fn participant ->
      %{
        number: 0,  # Single pairing for top cut
        tournament_id: tournament.id,
        round_id: round.id,
        participant_id: participant.id
      }
    end)
  end

  defp create_regular_pairings(tournament, round, active_participants, num_pairings) do
    case round.number do
      # First round: shuffle participants
      0 ->
        Logger.info("Creating first round pairings for tournament #{tournament.id}")
        partition_participants_into_pairings(
          active_participants |> Enum.shuffle(),
          num_pairings,
          tournament.format
        )

      _ ->
        case tournament.subformat do
          :bubble_rounds ->
            Logger.info("Creating bubble round pairings for tournament #{tournament.id}")
            create_bubble_round_pairings(tournament.id, round.number)
            |> partition_participants_into_pairings(num_pairings, tournament.format)

          :swiss ->
            Logger.info("Creating Swiss pairings for tournament #{tournament.id}")
            create_swiss_pairings(tournament, num_pairings)
        end
    end
    |> create_pairing_structs(tournament.id, round.id)
  end

  defp create_pairing_structs(pairings, tournament_id, round_id) do
    pairings
    |> Enum.with_index(fn pairing, index ->
      for participant <- pairing do
        %{
          number: index,
          tournament_id: tournament_id,
          round_id: round_id,
          participant_id: participant.id
        }
      end
    end)
    |> List.flatten()
  end

  defp partition_participants_into_pairings(participants, num_pairings, tournament_format) do
    participant_count = length(participants)
    
    Logger.debug("Partitioning #{participant_count} participants into #{num_pairings} pairings for #{tournament_format}")

    case tournament_format do
      :edh ->
        partition_edh_participants(participants, participant_count, num_pairings)

      :standard ->
        participants |> Enum.chunk_every(@standard_players_per_pairing)
    end
  end

  defp partition_edh_participants(participants, participant_count, num_pairings) do
    corrected_num_complete_pairings = calculate_complete_pairings(participant_count, num_pairings)

    case corrected_num_complete_pairings do
      0 ->
        participants |> Enum.chunk_every(@edh_min_players_per_pod)

      _ ->
        total_participants_for_complete_pairings = corrected_num_complete_pairings * @edh_players_per_pod

        complete_pairings =
          participants
          |> Enum.slice(0..(total_participants_for_complete_pairings - 1))
          |> Enum.chunk_every(@edh_players_per_pod)

        semi_complete_pairings =
          participants
          |> Enum.slice(total_participants_for_complete_pairings..participant_count)
          |> Enum.chunk_every(@edh_min_players_per_pod)

        complete_pairings ++ semi_complete_pairings
    end
  end

  defp calculate_complete_pairings(participant_count, num_pairings) do
    num_complete_pairings = rem(participant_count, num_pairings)

    corrected_num_complete_pairings =
      case participant_count do
        # Special cases for EDH: 6/9 participants should have even pairings of 3
        6 -> 0
        9 -> 0
        _ -> if num_complete_pairings == 0, do: num_pairings, else: num_complete_pairings
      end

    Logger.debug("Assigning #{num_pairings} pairings with #{corrected_num_complete_pairings} complete pairings [Total participants: #{participant_count}]")
    corrected_num_complete_pairings
  end

  defp create_bubble_round_pairings(tournament_id, current_round_number) do
    previous_round =
      Rounds.get_round_by_tournament_and_round_number!(tournament_id, current_round_number - 1)

    previous_round.pairings
    |> Enum.map(fn pairing ->
      %{
        id: pairing.participant_id,
        name: pairing.participant.name,
        points: pairing.points,
        winner: pairing.winner
      }
    end)
    |> Enum.group_by(fn p -> p.points end)
    |> Enum.sort(:desc)
    |> Enum.flat_map(fn {_, participants} ->
      Enum.shuffle(participants)
    end)
  end

  defp create_swiss_pairings(tournament, num_pairings) do
    participant_ids = tournament.participants |> Enum.map(& &1.id)

    Logger.info("Generating Swiss pairings with up to #{@max_swiss_retries} attempts to minimize repeat opponents")

    player_pairing_matrix = build_player_pairing_matrix(tournament, participant_ids)
    
    case attempt_optimal_swiss_pairings(player_pairing_matrix, num_pairings, tournament.format) do
      {:ok, pairings} ->
        pairings

      {:fallback, _reason} ->
        Logger.warning("Using fallback Swiss pairing algorithm for tournament #{tournament.id}")
        generate_swiss_pairings_with_retries(
          @max_swiss_retries,
          num_pairings,
          player_pairing_matrix,
          [],
          tournament.format
        )
        |> Enum.map(fn %{total_repeated_opponents: _, pairing: pairing} ->
          pairing |> Enum.map(&%{id: elem(&1, 0)})
        end)
    end
  end

  defp build_player_pairing_matrix(tournament, participant_ids) do
    mapped_rounds = extract_round_pairings(tournament.rounds)

    participant_ids
    |> Enum.map(fn id ->
      players_played_against = find_previous_opponents(mapped_rounds, id)
      players_not_played_with = calculate_unplayed_opponents(participant_ids, id, players_played_against)

      {id, players_played_against, players_not_played_with}
    end)
  end

  defp extract_round_pairings(rounds) do
    rounds
    |> Enum.map(fn round ->
      round.pairings
      |> Enum.map(fn pairing -> Map.take(pairing, [:number, :participant_id]) end)
    end)
    |> Enum.map(fn round ->
      Enum.group_by(round, & &1.number)
      |> Enum.map(fn {_round_number, participants} ->
        participants |> Enum.map(& &1.participant_id)
      end)
    end)
  end

  defp find_previous_opponents(mapped_rounds, participant_id) do
    mapped_rounds
    |> Enum.flat_map(fn round ->
      Enum.find(round, fn participants -> 
        participants |> Enum.find(&(&1 == participant_id)) 
      end) || []
    end)
    |> Enum.reject(&(&1 == participant_id))
    |> Enum.uniq()
  end

  defp calculate_unplayed_opponents(participant_ids, current_id, players_played_against) do
    :ordsets.subtract(
      :ordsets.from_list(participant_ids |> Enum.reject(&(&1 == current_id))),
      :ordsets.from_list(players_played_against)
    )
  end

  defp attempt_optimal_swiss_pairings(player_pairing_matrix, num_pairings, tournament_format) do
    partitioned_matrix = partition_participants_into_pairings(player_pairing_matrix, num_pairings, tournament_format)
    
    unique_pairings =
      partitioned_matrix
      |> Enum.reduce([], fn pairing_group, acc ->
        create_optimal_pairing_group(player_pairing_matrix, 0, acc, length(pairing_group))
      end)
      |> List.flatten()

    case Enum.any?(unique_pairings, &is_nil/1) do
      true ->
        {:fallback, "Could not create unique pairings"}

      false ->
        result_pairings = 
          partition_participants_into_pairings(
            unique_pairings |> Enum.map(fn id -> %{id: id} end),
            num_pairings,
            tournament_format
          )
        {:ok, result_pairings}
    end
  end

  defp create_optimal_pairing_group(matrix, index, taken_ids, group_size) do
    taken_ids = taken_ids |> List.flatten()

    case find_available_player(matrix, taken_ids) do
      nil -> 
        [nil]  # No available players
      
      {primary_id, _, available_opponents} ->
        available_opponents_filtered = available_opponents |> Enum.filter(&(not Enum.member?(taken_ids, &1)))
        
        case length(available_opponents_filtered) > index do
          false -> 
            [nil]  # Not enough opponents available
          
          true ->
            secondary_id = Enum.at(available_opponents_filtered, index + 1)
            Logger.debug("Pairing player #{primary_id} with available opponents")
            
            build_pairing_group(matrix, taken_ids, primary_id, secondary_id, group_size)
        end
    end
  end

  defp find_available_player(matrix, taken_ids) do
    matrix 
    |> Enum.filter(fn {player_id, _, _} -> not Enum.member?(taken_ids, player_id) end)
    |> Enum.at(0)
  end

  defp build_pairing_group(matrix, taken_ids, member_1, member_2, group_size) do
    case group_size do
      3 ->
        member_3 = find_common_unplayed_opponent(matrix, taken_ids, [member_1, member_2])
        [[member_1, member_2, member_3], taken_ids]

      4 ->
        member_3 = find_common_unplayed_opponent(matrix, taken_ids, [member_1, member_2])
        member_4 = find_common_unplayed_opponent(matrix, taken_ids, [member_1, member_2, member_3])
        [[member_1, member_2, member_3, member_4], taken_ids]

      _ ->
        [[member_1, member_2], taken_ids]
    end
  end

  defp find_common_unplayed_opponent(matrix, taken_ids, existing_members) do
    matrix
    |> Enum.find(fn {candidate_id, _, unplayed_opponents} ->
      not Enum.member?(taken_ids, candidate_id) and
      Enum.all?(existing_members, &Enum.member?(unplayed_opponents, &1))
    end)
    |> case do
      nil -> nil
      {id, _, _} -> id
    end
  end

  # Fallback algorithm with retry logic
  defp generate_swiss_pairings_with_retries(retries_left, num_pairings, player_matrix, best_round, tournament_format) when retries_left > 0 do
    Logger.debug("Swiss pairing attempt #{@max_swiss_retries - retries_left + 1}")

    shuffled_matrix = Enum.shuffle(player_matrix)
    pairings = partition_participants_into_pairings(shuffled_matrix, num_pairings, tournament_format)
    
    pairing_results = evaluate_pairing_quality(pairings)
    total_repeated = Enum.reduce(pairing_results, 0, fn result, acc -> result.total_repeated_opponents + acc end)
    
    best_score = case length(best_round) > 1 do
      true -> Enum.reduce(best_round, 0, fn result, acc -> result.total_repeated_opponents + acc end)
      false -> :infinity
    end
    
    is_better = total_repeated < best_score
    Logger.debug("Round has #{total_repeated} repeated opponents. Better than best? #{is_better}")
    
    new_best = if is_better, do: pairing_results, else: best_round
    
    generate_swiss_pairings_with_retries(
      retries_left - 1,
      num_pairings,
      player_matrix,
      new_best,
      tournament_format
    )
  end

  defp generate_swiss_pairings_with_retries(0, _num_pairings, _player_matrix, best_round, _tournament_format) do
    Logger.info("Swiss pairing generation completed")
    best_round
  end

  defp evaluate_pairing_quality(pairings) do
    pairings
    |> Enum.map(fn pairing ->
      players_in_pod = Enum.map(pairing, &elem(&1, 0))

      repeated_opponents =
        Enum.flat_map(pairing, &elem(&1, 1))
        |> Enum.reject(&Enum.member?(players_in_pod, &1))
        |> Enum.frequencies()
        |> Enum.reduce(0, fn {_id, repetitions}, acc -> repetitions + acc end)

      %{total_repeated_opponents: repeated_opponents, pairing: pairing}
    end)
  end
end