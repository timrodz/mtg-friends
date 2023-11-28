defmodule MtgFriendsWeb.Live.TournamentLive.Utils do
  use Phoenix.HTML, :raw

  alias MtgFriends.Rounds
  alias MtgFriends.Pairings

  def render_tournament_status(status) do
    case status do
      :inactive -> "Inactive 🟡"
      :active -> "Active 🟢"
      :finished -> "Ended 🔴"
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

  def create_pairings(tournament, round, top_cut_4?) do
    current_round_number = round.number

    participant_pairings =
      if top_cut_4? do
        num_pairings = round(Float.ceil(length(tournament.participants) / 4))

        get_overall_scores(tournament.rounds, num_pairings, true)
        |> Enum.take(4)
        |> Enum.map(fn participant ->
          %{
            number: current_round_number,
            tournament_id: tournament.id,
            round_id: round.id,
            participant_id: participant.id
          }
        end)
        |> IO.inspect(label: "PAIRINGS?")
      else
        case current_round_number do
          0 ->
            split_pairings_into_chunks(
              tournament.participants
              |> Enum.map(fn p -> %{id: p.id, name: p.name} end)
            )

          _ ->
            make_pairings_from_last_round_results(tournament, current_round_number)
            |> split_pairings_into_chunks()
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

  defp split_pairings_into_chunks(participants) do
    total_pairings = length(participants)

    with num_pairings <- round(Float.ceil(total_pairings / 4)),
         num_full_pods <- rem(total_pairings, num_pairings) do
      corrected_num_full_pods =
        case total_pairings do
          # with 6/9 participants, there should be even pairings of 3, therefore 0 full tables
          6 -> 0
          9 -> 0
          # when num_full_pods is 0, that means every pod is full. The result of the rem() division gives us 0 though
          _ -> if num_full_pods == 0, do: num_pairings, else: num_full_pods
        end

      IO.puts(
        "Assigning #{num_pairings} pairings with #{corrected_num_full_pods} full tables (4 participants) [Total pairings: #{total_pairings}]"
      )

      num_participants_for_full_pods = corrected_num_full_pods * 4

      full_pods =
        case corrected_num_full_pods do
          0 ->
            []

          _ ->
            participants
            |> Enum.slice(0..(num_participants_for_full_pods - 1))
            |> Enum.chunk_every(4)
        end

      semi_full_pods =
        participants
        |> Enum.slice(num_participants_for_full_pods..total_pairings)
        |> Enum.chunk_every(3)

      full_pods ++ semi_full_pods
    else
      _ -> nil
    end
  end

  def make_pairings_from_last_round_results(tournament, current_round_number) do
    case current_round_number do
      0 ->
        {:error, "current_round_number must be greater than 0"}

      _ ->
        previous_round = Rounds.get_round!(tournament.id, current_round_number - 1)

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
        |> Enum.reverse()
        |> Enum.flat_map(fn {_, participants} -> Enum.shuffle(participants) end)
    end
  end

  def get_overall_scores(
        rounds,
        num_pairings,
        scores_to_decimal \\ false
      ) do
    rounds
    |> Enum.flat_map(fn round -> round.pairings end)
    |> Enum.group_by(&Map.get(&1, :participant_id))
    |> Enum.map(fn {id, p} ->
      total_wins = Enum.reduce(p, 0, fn i, acc -> (i.winner && 1 + acc) || acc end)

      %{
        id: id,
        total_score:
          with score <-
                 Enum.reduce(p, 0, fn cur_pairing, acc ->
                   reduce_calculate_overall_score(rounds, num_pairings, cur_pairing, acc)
                 end) do
            case scores_to_decimal do
              true -> score |> Decimal.from_float()
              false -> score
            end
          end,
        win_rate: (total_wins / length(rounds) * 100) |> Decimal.from_float()
      }
    end)
    |> Enum.sort_by(fn p -> p.total_score end, :desc)
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
