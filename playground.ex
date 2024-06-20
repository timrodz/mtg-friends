pairing = [
  [A, B, C, D],
  [E, F, G, H],
  [I, J, K, L]
  # [M, N, O, P],
  # [Q, R, S, T]
]

group_length = length(pairing) |> IO.inspect(label: "group count")

IO.puts("\nROUND 2 ALGO : P1 stays, P2 shifts 1 space, P3 shifts 2 spaces, P4 shifts 4 spaces\n")

col_1_shift_amount = 0
col_2_shift_amount = 1
col_3_shift_amount = 2
col_4_shift_amount = 3

round_2_pairings =
  for group_number <- 0..(group_length - 1) do
    IO.puts("--- GROUP #{group_number + 1} ---")
    # COL 1
    col_1_value =
      List.pop_at(pairing, group_number)
      |> elem(0)
      |> Enum.at(0)
      |> IO.inspect(label: "col_1_value")

    # COL 2
    col_2_value =
      List.pop_at(pairing, group_number - col_2_shift_amount)
      |> elem(0)
      |> Enum.at(1)
      |> IO.inspect(label: "col_2_value")

    # COL 3
    col_3_value =
      List.pop_at(pairing, group_number - col_3_shift_amount)
      |> elem(0)
      |> Enum.at(2)
      |> IO.inspect(label: "col_3_value")

    # COL 4

    col_4_value =
      List.pop_at(pairing, group_number - col_4_shift_amount)
      |> elem(0)
      |> Enum.at(3)
      |> IO.inspect(label: "col_4_value")

    [col_1_value, col_2_value, col_3_value, col_4_value] |> Enum.reject(&is_nil/1)
  end
  |> IO.inspect(label: "round_2_pairings")

IO.puts(
  "\nROUND 3 ALGO : P1 shifts 1 space, P2 shifts 1 space (opposite direction of P1), P3 shifts 2 spaces, P4 shifts 2 spaces\n"
)
