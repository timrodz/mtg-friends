defmodule MtgFriendsWeb.Live.TournamentLive.Utils do
  use Phoenix.HTML, :raw

  alias MtgFriends.Rounds
  alias MtgFriends.Pairings

  def get_num_pairings(participant_count) do
    round(Float.ceil(participant_count / 4))
  end

  def render_tournament_status(status) do
    case status do
      :inactive -> "Open 🟢"
      :active -> "In progress 🔵"
      :finished -> "Finished 🔴"
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
      :single -> "1v1"
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
    num_pairings = get_num_pairings(length(tournament.participants))
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
              tournament.participants |> Enum.shuffle(),
              num_pairings
            )

          _ ->
            # TODO: Eventually this will decide the format of the round
            case tournament.subformat do
              _ ->
                make_pairings_from_last_round_results(tournament.id, round.number)
                |> partition_participants_into_pairings(num_pairings)
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

  defp partition_participants_into_pairings(participants, num_pairings) do
    participant_count = length(participants)

    # when num_complete_pairings is 0, that means every pairing is full
    # example: participant_count=16; num_pairings=4; rem(16/4) = 0
    num_complete_pairings = rem(participant_count, num_pairings)

    corrected_num_complete_pairings =
      case participant_count do
        # with 6/9 participants, there should be even pairings of 3, therefore 0 full pairings
        6 -> 0
        9 -> 0
        _ -> if num_complete_pairings == 0, do: num_pairings, else: num_complete_pairings
      end

    IO.puts(
      "Assigning #{num_pairings} pairings with #{corrected_num_complete_pairings} complete pairings [Total participants: #{participant_count}]"
    )

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
  end

  defp make_pairings_from_last_round_results(tournament_id, current_round_number) do
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

  # defp make_pairings_swiss(tournament) do
  #   participants = tournament.participants

  #   all_previous_rounds =
  #     tournament.rounds
  #     |> Enum.map(fn round ->
  #       # %{
  #       #   round_number: round.number,
  #       # pairings:
  #       round.pairings
  #       |> Enum.map(fn pairing -> Map.take(pairing, [:number, :participant_id]) end)

  #       # }
  #     end)
  #     |> IO.inspect(label: "pairings??")

  #   # players_played_against = participants |> Enum.map(fn participant -> nil end)
  # end

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

      total_wins = Enum.reduce(pairings, 0, fn i, acc -> (i.winner && 1 + acc) || acc end)

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
    if cur_round.active do
      cur_pairing.points + 0.0 + acc
    else
      case cur_round.number do
        0 ->
          cur_pairing.points + 0.0 + acc

        _ ->
          {decimals, ""} =
            Float.parse("0.00#{num_pairings - cur_pairing.number}")

          cur_pairing.points + decimals + acc
      end
    end
  end
end
