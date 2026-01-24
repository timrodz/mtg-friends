defmodule MtgFriends.Pairings do
  @moduledoc """
  The Pairings context.
  """

  defmodule PairingQuality do
    @moduledoc """
    Struct for pairing quality evaluation.
    """
    defstruct [:total_repeated_opponents, :pairing]

    @type t :: %__MODULE__{
            total_repeated_opponents: integer(),
            pairing: [integer()]
          }
  end

  defmodule PlayerPairing do
    @moduledoc """
    Struct for player pairing matrix entries.
    """
    defstruct [:id, :players_played_against, :players_not_played_with]

    @type t :: %__MODULE__{
            id: integer(),
            players_played_against: [integer()],
            players_not_played_with: [integer()]
          }
  end

  import Ecto.Query, warn: false
  alias MtgFriends.Rounds.Round
  alias MtgFriends.Tournaments.Tournament
  alias MtgFriends.Repo

  alias MtgFriends.Pairings.Pairing
  alias MtgFriends.Pairings.PairingParticipant

  alias MtgFriends.Participants
  alias MtgFriends.Rounds

  require Logger

  @doc """
  Returns the list of pairings.
  """
  @spec list_pairings() :: [Pairing.t()]
  def list_pairings do
    Repo.all(Pairing)
    |> Repo.preload(:pairing_participants)
  end

  @spec list_pairings(integer(), integer()) :: [Pairing.t()]
  def list_pairings(tournament_id, round_id) do
    Repo.all(
      from p in Pairing,
        where: p.tournament_id == ^tournament_id and p.round_id == ^round_id,
        preload: [:pairing_participants]
    )
  end

  @doc """
  Gets a single pairing.
  """
  @spec get_pairing!(integer()) :: Pairing.t() | no_return()
  def get_pairing!(id), do: Repo.get!(Pairing, id) |> Repo.preload(:pairing_participants)

  @spec get_pairing(integer()) :: {:ok, Pairing.t()} | {:error, :not_found}
  def get_pairing(id) do
    case Repo.get(Pairing, id) do
      nil -> {:error, :not_found}
      pairing -> {:ok, Repo.preload(pairing, :pairing_participants)}
    end
  end

  @spec get_pairing_participant!(integer(), integer()) :: PairingParticipant.t() | no_return()
  def get_pairing_participant!(pairing_id, participant_id),
    do:
      Repo.get_by!(PairingParticipant,
        pairing_id: pairing_id,
        participant_id: participant_id
      )

  @doc """
  Creates a pairing.
  """
  @spec create_pairing(map()) :: {:ok, Pairing.t()} | {:error, Ecto.Changeset.t()}
  def create_pairing(attrs \\ %{}) do
    %Pairing{}
    |> Pairing.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Creates multiple pairings with nested participants.
  Expects a list of maps where each map represents a Pairing and has a `pairing_participants` key.
  """
  @spec create_multiple_pairings([map()]) ::
          {:ok, [Pairing.t()]} | {:error, any()} | {:error, Ecto.Multi.name(), any(), map()}
  def create_multiple_pairings(pairings_data) do
    # Since insert_all doesn't support nested associations easily with IDs returned,
    # and we have a hierarchical structure now, we might need to use Ecto.Multi or Enum.each.
    # Given the scale of a tournament (tens of pairings), doing sequential inserts in a transaction is fine.

    Ecto.Multi.new()
    |> Ecto.Multi.run(:insert_pairings, fn repo, _ ->
      results =
        Enum.map(pairings_data, fn pairing_attrs ->
          %Pairing{}
          |> Pairing.changeset(pairing_attrs)
          |> Ecto.Changeset.put_assoc(:pairing_participants, pairing_attrs.pairing_participants)
          |> repo.insert()
        end)

      # If any failed, return error. Otherwise return list of successful pairings.
      failed = Enum.find(results, fn {status, _} -> status == :error end)

      if failed do
        failed
      else
        {:ok, Enum.map(results, fn {:ok, p} -> p end)}
      end
    end)
    |> Repo.transaction()
  end

  @doc """
  Updates a pairing.
  """
  @spec update_pairing(Pairing.t(), map()) :: {:ok, Pairing.t()} | {:error, Ecto.Changeset.t()}
  def update_pairing(%Pairing{} = pairing, attrs) do
    pairing
    |> Pairing.changeset(attrs)
    |> Repo.update()
  end

  @spec update_pairings(integer(), integer(), map()) ::
          {:ok, map()} | {:error, any()} | {:error, Ecto.Multi.name(), any(), map()}
  def update_pairings(tournament_id, round_id, form_params) do
    # form_params contains keys like "input-points-participant-<ID>" => "score"
    # We need to group these by Pairing (since we determine winner per pairing).
    # But filtering by tournament_id/round_id isn't directly giving us pairings unless we fetch them.

    pairings = list_pairings(tournament_id, round_id)

    multi = Ecto.Multi.new()

    multi =
      Enum.reduce(pairings, multi, fn pairing, acc_multi ->
        # Filter params relevant to this pairing's participants
        participants_in_pairing = Enum.map(pairing.pairing_participants, & &1.participant_id)

        relevant_scores =
          Enum.map(participants_in_pairing, fn pid ->
            score_str = form_params["input-points-participant-#{pid}"]

            if score_str do
              {points, ""} = Integer.parse(score_str)
              {pid, points}
            else
              nil
            end
          end)
          |> Enum.reject(&is_nil/1)

        if Enum.empty?(relevant_scores) do
          acc_multi
        else
          # Determine winner for this pairing
          {winner_pid, _} =
            highest = Enum.max_by(relevant_scores, fn {_, points} -> points end)

          # Handle draws - check if duplicates of max score exist
          max_points = elem(highest, 1)
          draw = Enum.count(relevant_scores, fn {_, p} -> p == max_points end) > 1

          winner_id = if draw, do: nil, else: winner_pid

          acc_multi =
            Ecto.Multi.update(
              acc_multi,
              "update_pairing_#{pairing.id}",
              Pairing.changeset(pairing, %{winner_id: winner_id, active: false})
            )

          # 2. Update PairingParticipants (points)
          Enum.reduce(relevant_scores, acc_multi, fn {pid, points}, inner_multi ->
            pp = Enum.find(pairing.pairing_participants, fn pp -> pp.participant_id == pid end)

            Ecto.Multi.update(
              inner_multi,
              "update_pp_#{pp.id}",
              PairingParticipant.changeset(pp, %{points: points})
            )
          end)
        end
      end)

    MtgFriends.Repo.transaction(multi)
  end

  @doc """
  Deletes a pairing.
  """
  @spec delete_pairing(Pairing.t()) :: {:ok, Pairing.t()} | {:error, Ecto.Changeset.t()}
  def delete_pairing(%Pairing{} = pairing) do
    Repo.delete(pairing)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking pairing changes.
  """
  @spec change_pairing(Pairing.t(), map()) :: Ecto.Changeset.t()
  def change_pairing(%Pairing{} = pairing, attrs \\ %{}) do
    Pairing.changeset(pairing, attrs)
  end

  @doc """
  Creates pairings for a tournament round using the appropriate algorithm.
  """
  @spec create_pairings_for_round(Tournament.t(), Round.t()) ::
          {:ok, [Pairing.t()]} | {:error, any()} | {:error, Ecto.Multi.name(), any(), map()}
  def create_pairings_for_round(tournament, round) do
    active_participants = Enum.filter(tournament.participants, fn p -> not p.is_dropped end)
    tournament_format = tournament.format
    num_pairings = calculate_num_pairings(length(active_participants), tournament_format)
    is_last_round? = tournament.round_count == round.number + 1
    is_top_cut_4? = is_last_round? && tournament.is_top_cut_4

    pairings_data =
      if is_top_cut_4? do
        create_top_cut_pairings(tournament, round)
      else
        create_regular_pairings(tournament, round, active_participants, num_pairings)
      end

    create_multiple_pairings(pairings_data)
  end

  @doc """
  Calculates the number of pairings needed based on participant count and format.
  """
  @spec calculate_num_pairings(integer(), atom()) :: integer()
  def calculate_num_pairings(participant_count, format) do
    edh_players_per_pod = 4
    standard_players_per_pairing = 2

    case format do
      :edh ->
        round(Float.ceil(participant_count / edh_players_per_pod))

      :standard ->
        round(Float.ceil(participant_count / standard_players_per_pairing))
    end
  end

  # Private pairing generation functions

  defp create_top_cut_pairings(tournament, round) do
    top_participants =
      Participants.get_participant_standings(tournament.participants)
      |> Enum.take(4)

    # For top cut, we create a single pairing with all 4 participants
    [
      %{
        tournament_id: tournament.id,
        round_id: round.id,
        active: true,
        pairing_participants:
          Enum.map(top_participants, fn p -> %{participant_id: p.id, points: 0} end)
      }
    ]
  end

  defp create_regular_pairings(tournament, round, active_participants, num_pairings) do
    grouped_participants =
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

            :round_robin ->
              Logger.info("Creating Round Robin pairings for tournament #{tournament.id}")
              create_round_robin_pairings(tournament, num_pairings, tournament.format)

            :swiss ->
              Logger.info("Creating Swiss pairings for tournament #{tournament.id}")
              create_swiss_pairings(tournament, num_pairings)
          end
      end

    # Transform into proper structures for insertion
    create_pairing_structs(grouped_participants, tournament.id, round.id)
  end

  defp create_pairing_structs(grouped_participants, tournament_id, round_id) do
    grouped_participants
    |> Enum.map(fn participants_in_pod ->
      %{
        tournament_id: tournament_id,
        round_id: round_id,
        active: true,
        pairing_participants:
          Enum.map(participants_in_pod, fn p ->
            %{participant_id: p.id, points: 0}
          end)
      }
    end)
  end

  defp partition_participants_into_pairings(participants, num_pairings, tournament_format) do
    participant_count = length(participants)
    standard_players_per_pairing = 2

    Logger.debug(
      "Partitioning #{participant_count} participants into #{num_pairings} pairings for #{tournament_format}"
    )

    case tournament_format do
      :edh ->
        partition_edh_participants(participants, participant_count, num_pairings)

      :standard ->
        participants |> Enum.chunk_every(standard_players_per_pairing)
    end
  end

  defp partition_edh_participants(participants, participant_count, num_pairings) do
    edh_players_per_pod = 4
    edh_min_players_per_pod = 3

    corrected_num_complete_pairings = calculate_complete_pairings(participant_count, num_pairings)

    case corrected_num_complete_pairings do
      0 ->
        participants |> Enum.chunk_every(edh_min_players_per_pod)

      _ ->
        total_participants_for_complete_pairings =
          corrected_num_complete_pairings * edh_players_per_pod

        complete_pairings =
          participants
          |> Enum.slice(0..(total_participants_for_complete_pairings - 1))
          |> Enum.chunk_every(edh_players_per_pod)

        semi_complete_pairings =
          participants
          |> Enum.slice(total_participants_for_complete_pairings..participant_count)
          |> Enum.chunk_every(edh_min_players_per_pod)

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

    Logger.debug(
      "Assigning #{num_pairings} pairings with #{corrected_num_complete_pairings} complete pairings [Total participants: #{participant_count}]"
    )

    corrected_num_complete_pairings
  end

  defp create_bubble_round_pairings(tournament_id, current_round_number) do
    previous_round =
      Rounds.get_round_by_tournament_and_round_number!(
        tournament_id,
        current_round_number - 1
      )
      |> Repo.preload(pairings: :pairing_participants)

    # Extract participants and their points from the previous round's pairings
    # Flatten all participants from all pairings
    previous_round.pairings
    |> Enum.flat_map(fn pairing ->
      pairing.pairing_participants
      |> Enum.map(fn pp ->
        %{
          id: pp.participant_id,
          points: pp.points
        }
      end)
    end)
    |> Enum.group_by(fn p -> p.points end)
    |> Enum.sort(:desc)
    |> Enum.flat_map(fn {_, participants} ->
      Enum.shuffle(participants)
    end)
    # Re-map to participant structs for consistency with other functions
    |> Enum.map(fn p -> %{id: p.id} end)
  end

  # Creates round robin pairings that maximize opponent variety.
  # Unlike Swiss, this ignores player scores and treats all players equally.
  # Designed for small tournaments (8-12 participants) where variety matters more than rankings.
  @spec create_round_robin_pairings(Tournament.t(), integer(), atom()) :: [[%{id: integer()}]]
  defp create_round_robin_pairings(tournament, num_pairings, tournament_format) do
    active_participant_ids =
      tournament.participants
      |> Enum.filter(fn p -> not p.is_dropped end)
      |> Enum.map(& &1.id)

    Logger.info(
      "Generating Round Robin pairings for #{length(active_participant_ids)} participants"
    )

    player_pairing_matrix = build_player_pairing_matrix(tournament, active_participant_ids)

    pods = build_round_robin_pods(player_pairing_matrix, num_pairings, tournament_format)

    pods
    |> Enum.map(fn pod_ids ->
      Enum.map(pod_ids, fn id -> %{id: id} end)
    end)
  end

  @spec build_round_robin_pods([PlayerPairing.t()], integer(), atom()) :: [[integer()]]
  defp build_round_robin_pods(player_pairing_matrix, num_pairings, tournament_format) do
    participant_count = length(player_pairing_matrix)
    base_pod_size = determine_pod_size(participant_count, num_pairings, tournament_format)
    remainder = rem(participant_count, num_pairings)

    {pods, _remaining} =
      Enum.reduce(1..num_pairings, {[], player_pairing_matrix}, fn pod_index, {acc_pods, remaining} ->
        case remaining do
          [] ->
            {acc_pods, []}

          _ ->
            current_pod_size =
              if remainder > 0 and pod_index <= remainder do
                base_pod_size + 1
              else
                min(base_pod_size, length(remaining))
              end

            {pod, updated_remaining} =
              find_optimal_pod(remaining, current_pod_size, player_pairing_matrix, tournament_format)

            {acc_pods ++ [pod], updated_remaining}
        end
      end)

    pods
  end

  @spec determine_pod_size(integer(), integer(), atom()) :: integer()
  defp determine_pod_size(participant_count, num_pairings, tournament_format) do
    case tournament_format do
      :edh ->
        if participant_count / num_pairings >= 4, do: 4, else: 3

      :standard ->
        2
    end
  end

  # Finds the optimal pod composition that minimizes repeat opponents.
  # Greedily selects players who have played against each other the least.
  # Works with both EDH (pods of 3-4) and Standard (pairs of 2) formats.
  @spec find_optimal_pod([PlayerPairing.t()], integer(), [PlayerPairing.t()], atom()) ::
          {[integer()], [PlayerPairing.t()]}
  defp find_optimal_pod([], _pod_size, _full_matrix, _tournament_format), do: {[], []}

  defp find_optimal_pod(remaining_players, pod_size, _full_matrix, _tournament_format) do
    actual_pod_size = min(pod_size, length(remaining_players))

    sorted_by_unplayed =
      remaining_players
      |> Enum.sort_by(fn player -> length(player.players_not_played_with) end, :desc)

    case sorted_by_unplayed do
      [] ->
        {[], []}

      [first | rest] ->
        pod_members = select_pod_members(first, rest, actual_pod_size - 1, [first])
        pod_ids = Enum.map(pod_members, & &1.id)

        updated_remaining =
          remaining_players
          |> Enum.reject(fn p -> p.id in pod_ids end)

        {pod_ids, updated_remaining}
    end
  end

  @spec select_pod_members(PlayerPairing.t(), [PlayerPairing.t()], integer(), [PlayerPairing.t()]) ::
          [PlayerPairing.t()]
  defp select_pod_members(_first, _candidates, 0, acc), do: acc

  defp select_pod_members(_first, [], _needed, acc), do: acc

  defp select_pod_members(first, candidates, needed, acc) do
    current_pod_ids = Enum.map(acc, & &1.id)

    best_candidate =
      candidates
      |> Enum.max_by(fn candidate ->
        unplayed_with_current =
          Enum.count(current_pod_ids, fn pod_id ->
            pod_id in candidate.players_not_played_with
          end)

        unplayed_with_current
      end)

    remaining_candidates = Enum.reject(candidates, &(&1.id == best_candidate.id))
    select_pod_members(first, remaining_candidates, needed - 1, acc ++ [best_candidate])
  end

  defp create_swiss_pairings(tournament, num_pairings) do
    max_swiss_retries = 12
    participant_ids = tournament.participants |> Enum.map(& &1.id)

    Logger.info(
      "Generating Swiss pairings with up to #{max_swiss_retries} attempts to minimize repeat opponents"
    )

    player_pairing_matrix = build_player_pairing_matrix(tournament, participant_ids)

    # returns list of lists of participant IDs: [[1, 2], [3, 4]]
    paired_ids =
      case attempt_optimal_swiss_pairings(player_pairing_matrix, num_pairings, tournament.format) do
        {:ok, pairings} ->
          pairings

        {:fallback, _reason} ->
          generate_swiss_pairings_with_retries(
            max_swiss_retries,
            num_pairings,
            player_pairing_matrix,
            [],
            tournament.format
          )
          |> Enum.map(fn %{pairing: pairing} -> pairing end)
      end

    # Map back to participant objects for consistency
    paired_ids
    |> Enum.map(fn ids_in_pod ->
      Enum.map(ids_in_pod, fn id -> %{id: id} end)
    end)
  end

  @spec build_player_pairing_matrix(Tournament.t(), [integer()]) :: [PlayerPairing.t()]
  defp build_player_pairing_matrix(tournament, participant_ids) do
    # Need to extract pairing history from previous rounds
    mapped_rounds = extract_round_pairings(tournament.rounds)

    participant_ids
    |> Enum.map(fn id ->
      players_played_against = find_previous_opponents(mapped_rounds, id)

      players_not_played_with =
        calculate_unplayed_opponents(participant_ids, id, players_played_against)

      %PlayerPairing{
        id: id,
        players_played_against: players_played_against,
        players_not_played_with: players_not_played_with
      }
    end)
  end

  defp extract_round_pairings(rounds) do
    rounds
    |> Enum.map(fn round ->
      # Check if already preloaded to avoid redundant queries
      pairings =
        if Ecto.assoc_loaded?(round.pairings),
          do: round.pairings,
          else: Repo.preload(round, pairings: :pairing_participants).pairings

      Enum.map(pairings, fn pairing ->
        pairing.pairing_participants |> Enum.map(& &1.participant_id)
      end)
    end)
  end

  defp find_previous_opponents(mapped_rounds, participant_id) do
    mapped_rounds
    |> Enum.flat_map(fn round_pairings_lists ->
      # Find the pod this player was in
      Enum.find(round_pairings_lists, fn pod_participants ->
        participant_id in pod_participants
      end) || []
    end)
    # Remove self
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
    partitioned_matrix =
      partition_participants_into_pairings(player_pairing_matrix, num_pairings, tournament_format)

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
        # result_pairings needs to reflect the structure expected by create_swiss_pairings
        # which expects list of lists of IDs
        result_pairings =
          partition_participants_into_pairings(
            unique_pairings,
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
        # No available players
        [nil]

      %PlayerPairing{id: primary_id, players_not_played_with: available_opponents} ->
        available_opponents_filtered =
          available_opponents |> Enum.filter(&(not Enum.member?(taken_ids, &1)))

        case length(available_opponents_filtered) > index do
          false ->
            # Not enough opponents available
            [nil]

          true ->
            secondary_id = Enum.at(available_opponents_filtered, index + 1)
            Logger.debug("Pairing player #{primary_id} with available opponents")

            build_pairing_group(matrix, taken_ids, primary_id, secondary_id, group_size)
        end
    end
  end

  defp find_available_player(matrix, taken_ids) do
    matrix
    |> Enum.filter(fn %PlayerPairing{id: player_id} -> not Enum.member?(taken_ids, player_id) end)
    |> Enum.at(0)
  end

  defp build_pairing_group(matrix, taken_ids, member_1, member_2, group_size) do
    case group_size do
      3 ->
        member_3 = find_common_unplayed_opponent(matrix, taken_ids, [member_1, member_2])
        [[member_1, member_2, member_3], taken_ids]

      4 ->
        member_3 = find_common_unplayed_opponent(matrix, taken_ids, [member_1, member_2])

        member_4 =
          find_common_unplayed_opponent(matrix, taken_ids, [member_1, member_2, member_3])

        [[member_1, member_2, member_3, member_4], taken_ids]

      _ ->
        [[member_1, member_2], taken_ids]
    end
  end

  defp find_common_unplayed_opponent(matrix, taken_ids, existing_members) do
    matrix
    |> Enum.find(fn %PlayerPairing{
                      id: candidate_id,
                      players_not_played_with: unplayed_opponents
                    } ->
      not Enum.member?(taken_ids, candidate_id) and
        Enum.all?(existing_members, &Enum.member?(unplayed_opponents, &1))
    end)
    |> case do
      nil -> nil
      %PlayerPairing{id: id} -> id
    end
  end

  # Fallback algorithm with retry logic
  defp generate_swiss_pairings_with_retries(
         retries_left,
         num_pairings,
         player_matrix,
         best_round,
         tournament_format
       )
       when retries_left > 0 do
    max_swiss_retries = 12
    Logger.debug("Swiss pairing attempt #{max_swiss_retries - retries_left + 1}")

    shuffled_matrix = Enum.shuffle(player_matrix)

    # Pairings here is list of lists of matrix entries {id, played, unplayed}
    pairings =
      partition_participants_into_pairings(shuffled_matrix, num_pairings, tournament_format)

    pairing_results = evaluate_pairing_quality(pairings)

    total_repeated =
      Enum.reduce(pairing_results, 0, fn result, acc -> result.total_repeated_opponents + acc end)

    best_score =
      case length(best_round) > 1 do
        true ->
          Enum.reduce(best_round, 0, fn result, acc -> result.total_repeated_opponents + acc end)

        false ->
          :infinity
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

  defp generate_swiss_pairings_with_retries(
         0,
         _num_pairings,
         _player_matrix,
         best_round,
         _tournament_format
       ) do
    Logger.info("Swiss pairing generation completed")
    best_round
  end

  @spec evaluate_pairing_quality([[PlayerPairing.t()]]) :: [PairingQuality.t()]
  defp evaluate_pairing_quality(pairings) do
    pairings
    |> Enum.map(fn pairing_matrix_entries ->
      # pairing_matrix_entries is list of PlayerPairing structs
      players_in_pod = Enum.map(pairing_matrix_entries, & &1.id)

      repeated_opponents =
        Enum.flat_map(pairing_matrix_entries, & &1.players_played_against)
        |> Enum.reject(&Enum.member?(players_in_pod, &1))
        |> Enum.frequencies()
        |> Enum.reduce(0, fn {_id, repetitions}, acc -> repetitions + acc end)

      # Return structure: pairing is list of IDs
      %PairingQuality{total_repeated_opponents: repeated_opponents, pairing: players_in_pod}
    end)
  end
end
