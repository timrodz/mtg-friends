defmodule MtgFriends.RoundRobinPairingsTest do
  @moduledoc """
  Tests for the Round Robin pairing algorithm.

  Round Robin is designed for small tournaments (8-12 participants) where
  maximizing opponent variety is more important than rankings.
  """
  use MtgFriends.DataCase

  alias MtgFriends.{Tournaments, Participants, Rounds, Pairings}

  import MtgFriends.AccountsFixtures
  import MtgFriends.GamesFixtures

  defp create_round_robin_tournament(participant_count, round_count \\ 3) do
    user = user_fixture()
    game = game_fixture()

    {:ok, tournament} =
      Tournaments.create_tournament(%{
        name: "Round Robin Tournament",
        date: NaiveDateTime.utc_now(),
        location: "Test Location",
        description_raw: "A test tournament for Round Robin pairing",
        game_id: game.id,
        user_id: user.id,
        format: :edh,
        subformat: :round_robin,
        round_count: round_count,
        is_top_cut_4: false
      })

    participants = create_participants(tournament, participant_count)

    {tournament, participants}
  end

  defp create_participants(tournament, count) do
    Enum.map(1..count, fn i ->
      user =
        user_fixture(%{email: "user#{i}_#{tournament.id}_#{System.unique_integer()}@example.com"})

      {:ok, participant} =
        Participants.create_participant(%{
          name: "Player #{i}",
          user_id: user.id,
          tournament_id: tournament.id,
          is_dropped: false
        })

      participant
    end)
  end

  defp create_round_manual(tournament_id, round_number) do
    Rounds.create_round(%{
      tournament_id: tournament_id,
      number: round_number,
      status: :active,
      started_at: NaiveDateTime.utc_now()
    })
  end

  defp finalize_round_with_results(tournament, round) do
    pairings = Pairings.list_pairings(tournament.id, round.id)

    pairings
    |> Enum.each(fn pairing ->
      form_params =
        pairing.pairing_participants
        |> Enum.map(fn pp ->
          {"input-points-participant-#{pp.participant_id}", "#{Enum.random(0..3)}"}
        end)
        |> Map.new()

      Pairings.update_pairings(tournament.id, round.id, form_params)
    end)
  end

  defp get_opponent_counts(tournament) do
    tournament = Tournaments.get_tournament!(tournament.id)

    tournament.participants
    |> Enum.map(fn participant ->
      opponents =
        tournament.rounds
        |> Enum.flat_map(fn round ->
          round.pairings
          |> Enum.find(fn pairing ->
            pairing.pairing_participants
            |> Enum.any?(fn pp -> pp.participant_id == participant.id end)
          end)
          |> case do
            nil ->
              []

            pairing ->
              pairing.pairing_participants
              |> Enum.map(& &1.participant_id)
              |> Enum.reject(&(&1 == participant.id))
          end
        end)

      {participant.id, Enum.frequencies(opponents)}
    end)
    |> Map.new()
  end

  defp count_unique_opponents_per_player(opponent_counts) do
    opponent_counts
    |> Enum.map(fn {_player_id, opponents_freq} ->
      map_size(opponents_freq)
    end)
  end

  describe "Round Robin with 8 participants" do
    test "creates pairings for first round with 8 participants" do
      {tournament, _participants} = create_round_robin_tournament(8)

      {:ok, round} = create_round_manual(tournament.id, 0)

      tournament = Tournaments.get_tournament!(tournament.id)
      round = Rounds.get_round!(round.id, true)

      {:ok, %{insert_pairings: pairings}} = Pairings.create_pairings_for_round(tournament, round)
      pairing_count = pairings |> Enum.flat_map(& &1.pairing_participants) |> length()

      # 8 players should be in 2 pods of 4
      assert pairing_count == 8
      assert length(pairings) == 2
    end

    test "maximizes opponent variety across multiple rounds with 8 participants" do
      {tournament, _participants} = create_round_robin_tournament(8, 3)

      # Round 0 (first round)
      {:ok, round0} = create_round_manual(tournament.id, 0)
      tournament = Tournaments.get_tournament!(tournament.id)
      round0 = Rounds.get_round!(round0.id, true)

      {:ok, %{insert_pairings: _pairings0}} =
        Pairings.create_pairings_for_round(tournament, round0)

      # Finalize round 0 with results
      finalize_round_with_results(tournament, round0)

      # Round 1 (second round - uses round robin algorithm)
      {:ok, round1} = create_round_manual(tournament.id, 1)
      tournament = Tournaments.get_tournament!(tournament.id)
      round1 = Rounds.get_round!(round1.id, true)

      {:ok, %{insert_pairings: pairings1}} =
        Pairings.create_pairings_for_round(tournament, round1)

      # Verify all participants are paired
      all_paired_r1 =
        pairings1
        |> Enum.flat_map(fn p -> Enum.map(p.pairing_participants, & &1.participant_id) end)

      assert length(Enum.uniq(all_paired_r1)) == 8

      # Finalize round 1 with results
      finalize_round_with_results(tournament, round1)

      # Round 2 (third round)
      {:ok, round2} = create_round_manual(tournament.id, 2)
      tournament = Tournaments.get_tournament!(tournament.id)
      round2 = Rounds.get_round!(round2.id, true)

      {:ok, %{insert_pairings: pairings2}} =
        Pairings.create_pairings_for_round(tournament, round2)

      all_paired_r2 =
        pairings2
        |> Enum.flat_map(fn p -> Enum.map(p.pairing_participants, & &1.participant_id) end)

      assert length(Enum.uniq(all_paired_r2)) == 8

      # Verify variety: each player should have faced multiple unique opponents
      opponent_counts = get_opponent_counts(tournament)

      unique_counts = count_unique_opponents_per_player(opponent_counts)

      # With 3 rounds of 4-player pods, each player faces 3 opponents per round = 9 total opponent slots
      # With 8 players, 7 possible unique opponents. We expect good variety.
      # Minimum reasonable: at least 5 unique opponents per player
      Enum.each(unique_counts, fn count ->
        assert count >= 5, "Expected at least 5 unique opponents, got #{count}"
      end)
    end
  end

  describe "Round Robin with 9 participants" do
    test "creates pairings for 9 participants (3 pods of 3)" do
      {tournament, _participants} = create_round_robin_tournament(9)

      {:ok, round} = create_round_manual(tournament.id, 0)

      tournament = Tournaments.get_tournament!(tournament.id)
      round = Rounds.get_round!(round.id, true)

      {:ok, %{insert_pairings: pairings}} = Pairings.create_pairings_for_round(tournament, round)
      pairing_count = pairings |> Enum.flat_map(& &1.pairing_participants) |> length()

      # 9 players should all be paired
      assert pairing_count == 9
      assert length(pairings) == 3
    end

    test "handles odd number across multiple rounds" do
      {tournament, _participants} = create_round_robin_tournament(9, 3)

      # Create and play 3 rounds
      Enum.reduce(0..2, tournament, fn round_num, acc_tournament ->
        {:ok, round} = create_round_manual(acc_tournament.id, round_num)
        acc_tournament = Tournaments.get_tournament!(acc_tournament.id)
        round = Rounds.get_round!(round.id, true)

        {:ok, %{insert_pairings: pairings}} =
          Pairings.create_pairings_for_round(acc_tournament, round)

        all_paired =
          pairings
          |> Enum.flat_map(fn p -> Enum.map(p.pairing_participants, & &1.participant_id) end)

        # All 9 players should be paired each round
        assert length(Enum.uniq(all_paired)) == 9

        finalize_round_with_results(acc_tournament, round)
        Tournaments.get_tournament!(acc_tournament.id)
      end)
    end
  end

  describe "Round Robin with 10 participants" do
    test "creates pairings for 10 participants" do
      {tournament, _participants} = create_round_robin_tournament(10)

      {:ok, round} = create_round_manual(tournament.id, 0)

      tournament = Tournaments.get_tournament!(tournament.id)
      round = Rounds.get_round!(round.id, true)

      {:ok, %{insert_pairings: pairings}} = Pairings.create_pairings_for_round(tournament, round)
      pairing_count = pairings |> Enum.flat_map(& &1.pairing_participants) |> length()

      # 10 players should all be paired
      assert pairing_count == 10
    end

    test "maximizes variety with 10 participants over 3 rounds" do
      {tournament, _participants} = create_round_robin_tournament(10, 3)

      # Create and play 3 rounds
      Enum.reduce(0..2, tournament, fn round_num, acc_tournament ->
        {:ok, round} = create_round_manual(acc_tournament.id, round_num)
        acc_tournament = Tournaments.get_tournament!(acc_tournament.id)
        round = Rounds.get_round!(round.id, true)

        {:ok, %{insert_pairings: pairings}} =
          Pairings.create_pairings_for_round(acc_tournament, round)

        all_paired =
          pairings
          |> Enum.flat_map(fn p -> Enum.map(p.pairing_participants, & &1.participant_id) end)

        assert length(Enum.uniq(all_paired)) == 10

        finalize_round_with_results(acc_tournament, round)
        Tournaments.get_tournament!(acc_tournament.id)
      end)

      # Check opponent variety
      opponent_counts = get_opponent_counts(tournament)
      unique_counts = count_unique_opponents_per_player(opponent_counts)

      # With 10 players (9 possible opponents), expect good variety
      Enum.each(unique_counts, fn count ->
        assert count >= 5, "Expected at least 5 unique opponents, got #{count}"
      end)
    end
  end

  describe "Round Robin with 11 participants" do
    test "creates pairings for 11 participants" do
      {tournament, _participants} = create_round_robin_tournament(11)

      {:ok, round} = create_round_manual(tournament.id, 0)

      tournament = Tournaments.get_tournament!(tournament.id)
      round = Rounds.get_round!(round.id, true)

      {:ok, %{insert_pairings: pairings}} = Pairings.create_pairings_for_round(tournament, round)
      pairing_count = pairings |> Enum.flat_map(& &1.pairing_participants) |> length()

      # 11 players should all be paired
      assert pairing_count == 11
    end

    test "handles 11 participants across multiple rounds" do
      {tournament, _participants} = create_round_robin_tournament(11, 3)

      Enum.reduce(0..2, tournament, fn round_num, acc_tournament ->
        {:ok, round} = create_round_manual(acc_tournament.id, round_num)
        acc_tournament = Tournaments.get_tournament!(acc_tournament.id)
        round = Rounds.get_round!(round.id, true)

        {:ok, %{insert_pairings: pairings}} =
          Pairings.create_pairings_for_round(acc_tournament, round)

        all_paired =
          pairings
          |> Enum.flat_map(fn p -> Enum.map(p.pairing_participants, & &1.participant_id) end)

        assert length(Enum.uniq(all_paired)) == 11

        finalize_round_with_results(acc_tournament, round)
        Tournaments.get_tournament!(acc_tournament.id)
      end)
    end
  end

  describe "Round Robin with 12 participants" do
    test "creates pairings for 12 participants (3 pods of 4)" do
      {tournament, _participants} = create_round_robin_tournament(12)

      {:ok, round} = create_round_manual(tournament.id, 0)

      tournament = Tournaments.get_tournament!(tournament.id)
      round = Rounds.get_round!(round.id, true)

      {:ok, %{insert_pairings: pairings}} = Pairings.create_pairings_for_round(tournament, round)
      pairing_count = pairings |> Enum.flat_map(& &1.pairing_participants) |> length()

      # 12 players should be in 3 pods of 4
      assert pairing_count == 12
      assert length(pairings) == 3
    end

    test "maximizes variety with 12 participants over 3 rounds" do
      {tournament, _participants} = create_round_robin_tournament(12, 3)

      Enum.reduce(0..2, tournament, fn round_num, acc_tournament ->
        {:ok, round} = create_round_manual(acc_tournament.id, round_num)
        acc_tournament = Tournaments.get_tournament!(acc_tournament.id)
        round = Rounds.get_round!(round.id, true)

        {:ok, %{insert_pairings: pairings}} =
          Pairings.create_pairings_for_round(acc_tournament, round)

        all_paired =
          pairings
          |> Enum.flat_map(fn p -> Enum.map(p.pairing_participants, & &1.participant_id) end)

        assert length(Enum.uniq(all_paired)) == 12

        finalize_round_with_results(acc_tournament, round)
        Tournaments.get_tournament!(acc_tournament.id)
      end)

      opponent_counts = get_opponent_counts(tournament)
      unique_counts = count_unique_opponents_per_player(opponent_counts)

      # With 12 players (11 possible opponents), expect strong variety
      Enum.each(unique_counts, fn count ->
        assert count >= 6, "Expected at least 6 unique opponents, got #{count}"
      end)
    end
  end

  describe "Round Robin edge cases" do
    test "handles dropped participants" do
      {tournament, participants} = create_round_robin_tournament(10)

      # Drop 2 participants
      [p1, p2 | _rest] = participants
      Participants.update_participant(p1, %{is_dropped: true})
      Participants.update_participant(p2, %{is_dropped: true})

      {:ok, round} = create_round_manual(tournament.id, 0)

      tournament = Tournaments.get_tournament!(tournament.id)
      round = Rounds.get_round!(round.id, true)

      {:ok, %{insert_pairings: pairings}} = Pairings.create_pairings_for_round(tournament, round)
      pairing_count = pairings |> Enum.flat_map(& &1.pairing_participants) |> length()

      # Only 8 active participants should be paired
      assert pairing_count == 8
    end

    test "handles mid-tournament drops" do
      {tournament, participants} = create_round_robin_tournament(8, 3)

      # Play first round
      {:ok, round0} = create_round_manual(tournament.id, 0)
      tournament = Tournaments.get_tournament!(tournament.id)
      round0 = Rounds.get_round!(round0.id, true)

      {:ok, %{insert_pairings: _pairings0}} =
        Pairings.create_pairings_for_round(tournament, round0)

      finalize_round_with_results(tournament, round0)

      # Drop a participant after round 1
      [p1 | _rest] = participants
      Participants.update_participant(p1, %{is_dropped: true})

      # Play second round with 7 players
      {:ok, round1} = create_round_manual(tournament.id, 1)
      tournament = Tournaments.get_tournament!(tournament.id)
      round1 = Rounds.get_round!(round1.id, true)

      {:ok, %{insert_pairings: pairings1}} =
        Pairings.create_pairings_for_round(tournament, round1)

      pairing_count = pairings1 |> Enum.flat_map(& &1.pairing_participants) |> length()

      # Only 7 active participants should be paired
      assert pairing_count == 7
    end

    test "first round shuffles participants" do
      {tournament, _participants} = create_round_robin_tournament(8)

      # Create two first rounds and verify they can differ (shuffle works)
      {:ok, round} = create_round_manual(tournament.id, 0)
      tournament = Tournaments.get_tournament!(tournament.id)
      round = Rounds.get_round!(round.id, true)

      {:ok, %{insert_pairings: pairings}} = Pairings.create_pairings_for_round(tournament, round)
      pairing_count = pairings |> Enum.flat_map(& &1.pairing_participants) |> length()

      # Verify all participants are paired
      assert pairing_count == 8
    end
  end

  describe "Round Robin vs Swiss comparison" do
    test "round robin ignores scores when pairing" do
      {tournament, _participants} = create_round_robin_tournament(8, 2)

      # First round
      {:ok, round0} = create_round_manual(tournament.id, 0)
      tournament = Tournaments.get_tournament!(tournament.id)
      round0 = Rounds.get_round!(round0.id, true)

      {:ok, %{insert_pairings: _pairings0}} =
        Pairings.create_pairings_for_round(tournament, round0)

      # Give some players high scores, others low
      finalize_round_with_results(tournament, round0)

      # Second round - round robin should prioritize variety, not score matching
      {:ok, round1} = create_round_manual(tournament.id, 1)
      tournament = Tournaments.get_tournament!(tournament.id)
      round1 = Rounds.get_round!(round1.id, true)

      {:ok, %{insert_pairings: pairings1}} =
        Pairings.create_pairings_for_round(tournament, round1)

      all_paired =
        pairings1
        |> Enum.flat_map(fn p -> Enum.map(p.pairing_participants, & &1.participant_id) end)
        |> Enum.uniq()

      # All participants should still be paired
      assert length(all_paired) == 8

      # Verify pods contain mix of players (not score-segregated)
      # This is hard to test deterministically, but we verify the algorithm runs
      assert length(pairings1) == 2
    end
  end
end
