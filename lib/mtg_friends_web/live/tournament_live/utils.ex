defmodule MtgFriendsWeb.Live.TournamentLive.Utils do
  def split_pairings_into_chunks(participants) do
    total_pairings = length(participants)

    with num_pairings <- round(Float.ceil(total_pairings / 4)),
         num_full_pods <- rem(total_pairings, num_pairings) do
      num_full_pods =
        case total_pairings do
          # with 6 participants, there should be 2 pairings of 3, therefore 0 full tables
          6 -> 0
          # when num_full_pods is 0, that means every pod is full. The result of the rem() division gives us 0 though
          _ -> if num_full_pods == 0, do: num_pairings, else: num_full_pods
        end

      IO.puts(
        "Assigning #{num_pairings} pairings with #{num_full_pods} full tables (4 participants) [Total pairings: #{total_pairings}]"
      )

      num_participants_for_full_pods = num_full_pods * 4

      full_pods =
        case num_full_pods do
          0 ->
            []

          _ ->
            participants
            |> Enum.slice(0..(num_participants_for_full_pods - 1))
            |> Enum.chunk_every(4)
            |> IO.inspect(label: "full pods")
        end

      semi_full_pods =
        participants
        |> Enum.slice(num_participants_for_full_pods..total_pairings)
        |> Enum.chunk_every(3)
        |> IO.inspect(label: "semi-full pods")

      full_pods ++ semi_full_pods
    else
      _ -> nil
    end
  end

  def create_pairings_from_overall_scores(
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
              true -> score |> Decimal.from_float() |> Decimal.round(3)
              false -> score
            end
          end,
        win_rate:
          "#{(total_wins / length(rounds) * 100) |> Decimal.from_float() |> Decimal.round(2)}%"
      }
    end)
    |> Enum.sort_by(fn p -> p.total_score end, :desc)
  end

  defp reduce_calculate_overall_score(rounds, num_pairings, cur_pairing, acc) do
    cur_round = Enum.find(rounds, fn r -> r.id == cur_pairing.round_id end)

    case cur_round.number do
      0 ->
        # Add 0.0 to make this number a float
        cur_pairing.points + 0.0 + acc

      _ ->
        {decimals, ""} =
          Float.parse("0.00#{num_pairings - cur_pairing.number}")

        cur_pairing.points + decimals + acc
    end
  end
end
