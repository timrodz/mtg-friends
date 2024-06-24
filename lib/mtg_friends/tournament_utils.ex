defmodule MtgFriends.TournamentUtils do
  use Phoenix.HTML, :raw

  alias MtgFriends.Rounds
  alias MtgFriends.Pairings

  def get_num_pairings(participant_count, format) do
    case format do
      :edh ->
        round(Float.ceil(participant_count / 4))

      :standard ->
        round(Float.ceil(participant_count / 2))
    end
  end

  def render_status(status) do
    case status do
      :inactive -> "Open"
      :active -> "In progress"
      :finished -> "Finished"
    end
  end

  def render_status_extra(status) do
    case status do
      :inactive -> "Open 🟢"
      :active -> "In progress 🔵"
      :finished -> "Finished 🔴"
    end
  end

  def render_round_status(status) do
    case status do
      :inactive -> "Pairing players"
      :active -> "In progress"
      :finished -> "Finished"
      _ -> "??"
    end
  end

  def render_round_status_extra(status) do
    case status do
      :inactive -> "Pairing players 🟩"
      :active -> "In progress 🟦"
      :finished -> "Finished 🟥"
    end
  end

  def render_decklist(decklist) do
    case decklist do
      nil ->
        raw("<p class=\"text-orange-300\">---</p>")

      _ ->
        case validate_decklist_url(decklist) do
          true ->
            raw(
              "<span class=\"inline-flex items-center rounded-md bg-orange-200 px-2 py-1 text-xs font-medium text-zinc-700 ring-1 ring-inset ring-teal-900/10\"><a href=#{decklist} target=\"_blank\">Decklist</a></span>"
            )

          false ->
            raw("<p>#{decklist}</p>")
        end
    end
  end

  def validate_decklist_url(url) do
    uri = URI.parse(url)
    uri.scheme != nil && uri.host =~ "."
  end

  def render_format(format) do
    case format do
      :edh -> "Commander (EDH)"
      :standard -> "Standard"
      nil -> ""
    end
  end

  def render_subformat(subformat) do
    case subformat do
      :bubble_rounds -> "Bubble Rounds"
      :swiss -> "Swiss Rounds"
      nil -> ""
    end
  end

  def render_subformat_description(subformat) do
    case subformat do
      :bubble_rounds ->
        "Pods are determined by last round standings"

      :swiss ->
        "Pods are determined by trying to make sure each participant plays every opponent at least once"

      nil ->
        ""
    end
  end

  def create_pairings(tournament, round) do
    active_participants = Enum.filter(tournament.participants, fn p -> not p.is_dropped end)
    tournament_format = tournament.format
    num_pairings = get_num_pairings(length(active_participants), tournament_format)
    is_last_round? = tournament.round_count == round.number + 1
    is_top_cut_4? = is_last_round? && tournament.is_top_cut_4

    participant_pairings =
      if is_top_cut_4? do
        get_overall_scores(tournament.rounds, num_pairings)
        |> Enum.take(4)
        |> Enum.map(fn participant ->
          %{
            # Pairing number is 0 because there's only 1 pairing
            number: 0,
            tournament_id: tournament.id,
            round_id: round.id,
            participant_id: participant.id
          }
        end)
      else
        case round.number do
          # First round: Simply shuffle participants
          0 ->
            partition_participants_into_pairings(
              active_participants |> Enum.shuffle(),
              num_pairings,
              tournament_format
            )

          _ ->
            case tournament.subformat do
              :bubble_rounds ->
                make_edh_bubble_pairings(tournament.id, round.number)
                |> partition_participants_into_pairings(num_pairings, tournament_format)

              :swiss ->
                make_edh_swiss_pairings(tournament, num_pairings, tournament_format)
            end
        end
        |> Enum.with_index(fn pairing, index ->
          for participant <- pairing do
            %{
              number: index,
              tournament_id: tournament.id,
              round_id: round.id,
              participant_id: participant.id
            }
          end
        end)
        |> List.flatten()
      end

    Pairings.create_multiple_pairings(participant_pairings)
  end

  defp get_num_complete_pairings(participant_count, num_pairings, format) do
    # when num_complete_pairings is 0, that means every pairing is full
    # example: participant_count=16; num_pairings=4; rem(16/4) = 0
    num_complete_pairings = rem(participant_count, num_pairings)

    corrected_num_complete_pairings =
      case format do
        :edh ->
          case participant_count do
            # with 6/9 participants, there should be even pairings of 3, therefore 0 full pairings
            6 -> 0
            9 -> 0
            _ -> if num_complete_pairings == 0, do: num_pairings, else: num_complete_pairings
          end

        :standard ->
          num_complete_pairings
      end

    IO.puts(
      "Assigning #{num_pairings} pairings with #{corrected_num_complete_pairings} complete pairings [Total participants: #{participant_count}]"
    )

    corrected_num_complete_pairings
  end

  defp partition_participants_into_pairings(participants, num_pairings, tournament_format) do
    participant_count = length(participants)

    case tournament_format do
      :edh ->
        corrected_num_complete_pairings =
          get_num_complete_pairings(participant_count, num_pairings, tournament_format)

        case corrected_num_complete_pairings do
          0 ->
            participants |> Enum.chunk_every(3)

          _ ->
            total_participants_for_complete_pairings = corrected_num_complete_pairings * 4

            complete_pairings =
              participants
              |> Enum.slice(0..(total_participants_for_complete_pairings - 1))
              |> Enum.chunk_every(4)

            semi_complete_pairings =
              participants
              |> Enum.slice(total_participants_for_complete_pairings..participant_count)
              |> Enum.chunk_every(3)

            complete_pairings ++ semi_complete_pairings
        end

      # Doesn't support byes yet
      :standard ->
        participants |> Enum.chunk_every(2)
    end
  end

  defp make_edh_bubble_pairings(tournament_id, current_round_number) do
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
    # Sort by highest to lowest, so complete pairings are rendered first in the UI
    |> Enum.sort(:desc)
    |> Enum.flat_map(fn {_, participants} ->
      Enum.shuffle(participants)
    end)
  end

  defp member_check(taken_ids, member) do
    not Enum.member?(taken_ids, member)
  end

  defp do_thing(matrix, index, taken_ids, members) do
    taken_ids = taken_ids |> List.flatten()

    player =
      matrix |> Enum.filter(&member_check(taken_ids, elem(&1, 0))) |> Enum.at(0)

    {id, _, players_not_played_with} = player

    revised_players_not_played_with =
      players_not_played_with |> Enum.filter(&member_check(taken_ids, &1))

    member_1 = id
    member_2 = revised_players_not_played_with |> Enum.at(index + 1)

    IO.puts("Iterating over player #{id} / Group: [#{member_1}, #{member_2}]")

    case members do
      3 ->
        member_3 =
          with m <-
                 matrix
                 |> Enum.find(fn {a, _, c} ->
                   Enum.member?(c, member_1) and Enum.member?(c, member_2) and
                     member_check(taken_ids, a)
                 end),
               false <- is_nil(m) do
            m |> elem(0)
          else
            _ ->
              nil
          end

        [[member_1, member_2, member_3], taken_ids]

      4 ->
        member_3 =
          with m <-
                 matrix
                 |> Enum.find(fn {a, _, c} ->
                   Enum.member?(c, member_1) and Enum.member?(c, member_2) and
                     member_check(taken_ids, a)
                 end),
               false <- is_nil(m) do
            m |> elem(0)
          else
            _ ->
              nil
          end

        member_4 =
          with m <-
                 matrix
                 |> Enum.find(fn {a, _, c} ->
                   Enum.member?(c, member_1) and Enum.member?(c, member_2) and
                     Enum.member?(c, member_3) and member_check(taken_ids, a)
                 end),
               false <- is_nil(m) do
            m |> elem(0)
          else
            _ ->
              nil
          end

        [[member_1, member_2, member_3, member_4], taken_ids]

      _ ->
        [[member_1, member_2], taken_ids]
    end
  end

  defp make_edh_swiss_pairings(tournament, num_pairings, tournament_format) do
    participant_ids = tournament.participants |> Enum.map(& &1.id)
    num_max_retries = 12

    IO.puts(
      "Generating #{num_max_retries} pairings to find the one with the least amount of repetitions"
    )

    mapped_rounds =
      tournament.rounds
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

    # Maps players to every opponent they've played against
    player_pairing_matrix =
      participant_ids
      |> Enum.map(fn id ->
        players_played_against =
          mapped_rounds
          |> Enum.flat_map(fn r ->
            Enum.find(r, fn participants -> participants |> Enum.find(&(&1 == id)) end)
          end)
          # Remove the id of the participant, because it's pointless to say they've played against themselves
          |> Enum.reject(&(&1 == id))
          |> Enum.uniq()

        players_not_played_with =
          :ordsets.subtract(
            :ordsets.from_list(participant_ids |> Enum.reject(&(&1 == id))),
            :ordsets.from_list(players_played_against)
          )

        {id, players_played_against, players_not_played_with}
      end)

    corrected_num_complete_pairings =
      partition_participants_into_pairings(player_pairing_matrix, num_pairings, tournament_format)

    unique_pairings =
      corrected_num_complete_pairings
      |> Enum.reduce([], fn p, acc ->
        do_thing(player_pairing_matrix, 0, acc, length(p))
      end)
      |> List.flatten()

    # if any of the unique pairings is nil, that means not every pairing is unique, so we might as well default to the old method
    case Enum.any?(unique_pairings, &is_nil/1) do
      true ->
        generate_edh_swiss_round_pairings(
          num_max_retries,
          num_pairings,
          player_pairing_matrix,
          [],
          tournament_format
        )
        |> IO.inspect(label: "final swiss pairing", charlists: :as_lists)
        |> Enum.map(fn %{total_repeated_opponents: _, pairing: pairing} ->
          pairing |> Enum.map(&%{id: elem(&1, 0)})
        end)

      false ->
        partition_participants_into_pairings(
          unique_pairings |> Enum.map(fn id -> %{id: id} end),
          num_pairings,
          tournament_format
        )
    end
  end

  defp generate_edh_swiss_round_pairings(
         index,
         num_pairings,
         player_pairing_matrix,
         best_pairing_round,
         tournament_format
       ) do
    # This function generates pairings until it finds the "best pairing round", which represents
    # the pairing with the least amount of repeated opponents

    IO.puts("generate_edh_swiss_round_pairings: version #{index}")

    # Because I'm lazy, I'm literally just shuffling players around until I find the best outcomes... lol
    shuffled_pairings = Enum.shuffle(player_pairing_matrix)

    pairings =
      partition_participants_into_pairings(shuffled_pairings, num_pairings, tournament_format)

    pairing_results =
      pairings
      |> Enum.map(fn pairing ->
        players_in_pod = Enum.map(pairing, &elem(&1, 0))

        players_this_pod_has_played_against =
          Enum.flat_map(pairing, &elem(&1, 1))
          # Remove players in this pod, because they can't play against themselves
          |> Enum.reject(&(!Enum.member?(players_in_pod, &1)))
          # Frequencies gives you a count of all repetitions in a list
          |> Enum.frequencies()

        repeated_opponents =
          players_this_pod_has_played_against
          |> Enum.reduce(0, fn {_id, repetitions}, acc -> repetitions + acc end)

        %{total_repeated_opponents: repeated_opponents, pairing: pairing}
      end)

    total_repeated_opponents =
      Enum.reduce(pairing_results, 0, fn i, acc -> i.total_repeated_opponents + acc end)

    num_repeated_opponents_best_pairing =
      length(best_pairing_round) > 1 and
        Enum.reduce(best_pairing_round, 0, fn i, acc -> i.total_repeated_opponents + acc end)

    is_this_pairing_better? = total_repeated_opponents < num_repeated_opponents_best_pairing

    IO.puts(
      "This round of pairings has #{total_repeated_opponents} repeated opponents. Is this pairing better? #{is_this_pairing_better?}\n"
    )

    # We generate different EDH pairings until we hit index: 0
    if index > 0 do
      generate_edh_swiss_round_pairings(
        index - 1,
        num_pairings,
        player_pairing_matrix,
        case is_this_pairing_better? do
          true -> pairing_results
          false -> best_pairing_round
        end,
        tournament_format
      )
    else
      best_pairing_round
    end
  end

  def get_overall_scores(rounds, num_pairings) do
    rounds
    |> Enum.flat_map(fn round -> round.pairings end)
    |> Enum.group_by(&Map.get(&1, :participant_id))
    |> Enum.map(fn {id, pairings} ->
      total_score =
        Enum.reduce(pairings, 0, fn cur_pairing, acc ->
          reduce_calculate_overall_score(rounds, num_pairings, cur_pairing, acc)
        end)
        |> Decimal.from_float()
        |> Decimal.round(3)

      total_wins =
        Enum.reduce(pairings, 0, fn i, acc -> (i.winner && 1 + acc) || acc end)

      %{
        id: id,
        total_score: total_score,
        win_rate: (total_wins / length(rounds) * 100) |> Decimal.from_float()
      }
    end)
    |> Enum.sort_by(&{&1.total_score, &1.win_rate}, :desc)
  end

  defp reduce_calculate_overall_score(rounds, num_pairings, cur_pairing, acc) do
    cur_round =
      Enum.find(rounds, fn r -> r.id == cur_pairing.round_id end)

    # Adding 0.0 converts ints into floats
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
