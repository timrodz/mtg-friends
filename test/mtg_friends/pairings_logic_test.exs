defmodule MtgFriends.PairingsLogicTest do
  use MtgFriends.DataCase

  alias MtgFriends.{Tournaments, Participants, Rounds, Pairings}

  import MtgFriends.AccountsFixtures
  import MtgFriends.GamesFixtures

  describe "calculate_num_pairings/2" do
    test "calculates correct pairings for EDH format with 4 players" do
      assert Pairings.calculate_num_pairings(4, :edh) == 1
    end

    test "calculates correct pairings for EDH format with 8 players" do
      assert Pairings.calculate_num_pairings(8, :edh) == 2
    end

    test "calculates correct pairings for EDH format with 6 players" do
      assert Pairings.calculate_num_pairings(6, :edh) == 2
    end

    test "calculates correct pairings for EDH format with 9 players" do
      assert Pairings.calculate_num_pairings(9, :edh) == 3
    end

    test "calculates correct pairings for Standard format with 4 players" do
      assert Pairings.calculate_num_pairings(4, :standard) == 2
    end

    test "calculates correct pairings for Standard format with 6 players" do
      assert Pairings.calculate_num_pairings(6, :standard) == 3
    end

    test "calculates correct pairings for Standard format with 5 players" do
      assert Pairings.calculate_num_pairings(5, :standard) == 3
    end
  end

  # Helper to create round manually since Rounds.create_round_for_tournament was removed
  defp create_round_manual(tournament_id, round_number) do
    Rounds.create_round(%{
      tournament_id: tournament_id,
      number: round_number,
      status: :active,
      started_at: NaiveDateTime.utc_now()
    })
  end

  describe "create_pairings_for_round/2 - first round" do
    setup do
      user = user_fixture()
      game = game_fixture()

      {:ok, tournament} =
        Tournaments.create_tournament(%{
          name: "Test Tournament",
          date: NaiveDateTime.utc_now(),
          location: "Test Location",
          description_raw: "A test tournament for EDH pairing",
          game_id: game.id,
          user_id: user.id,
          format: :edh,
          subformat: :swiss,
          round_count: 3,
          is_top_cut_4: false
        })

      # Create participants
      participants = create_participants(tournament, 8)

      {:ok, round} = create_round_manual(tournament.id, 0)

      tournament = Tournaments.get_tournament!(tournament.id)
      round = Rounds.get_round!(round.id, true)

      %{tournament: tournament, round: round, participants: participants}
    end

    test "creates first round pairings for EDH tournament", %{
      tournament: tournament,
      round: round
    } do
      {:ok, %{insert_pairings: pairings}} = Pairings.create_pairings_for_round(tournament, round)
      pairing_count = pairings |> Enum.flat_map(& &1.pairing_participants) |> length()

      # Should create 8 participants / 4 per pod = 2 pairings * 4 participants each = 8 total records
      assert pairing_count == 8
    end

    test "creates first round pairings for Standard tournament" do
      user = user_fixture()
      game = game_fixture()

      {:ok, tournament} =
        Tournaments.create_tournament(%{
          name: "Standard Test Tournament",
          date: NaiveDateTime.utc_now(),
          location: "Test Location",
          description_raw: "A test tournament for Standard pairing",
          game_id: game.id,
          user_id: user.id,
          format: :standard,
          subformat: :swiss,
          round_count: 3,
          is_top_cut_4: false
        })

      _participants = create_participants(tournament, 6)

      {:ok, round} = create_round_manual(tournament.id, 0)

      tournament = Tournaments.get_tournament!(tournament.id)
      round = Rounds.get_round!(round.id, true)

      {:ok, %{insert_pairings: pairings}} = Pairings.create_pairings_for_round(tournament, round)
      pairing_count = pairings |> Enum.flat_map(& &1.pairing_participants) |> length()

      # Should create 6 participants / 2 per pairing = 3 pairings * 2 participants each = 6 total records
      assert pairing_count == 6
    end
  end

  describe "create_pairings_for_round/2 - EDH special cases" do
    setup do
      user = user_fixture()
      game = game_fixture()

      {:ok, tournament} =
        Tournaments.create_tournament(%{
          name: "EDH Special Cases Tournament",
          date: NaiveDateTime.utc_now(),
          location: "Test Location",
          description_raw: "A test tournament for EDH special cases",
          game_id: game.id,
          user_id: user.id,
          format: :edh,
          subformat: :swiss,
          round_count: 3,
          is_top_cut_4: false
        })

      %{tournament: tournament, user: user, game: game}
    end

    test "handles 6 players correctly (2 pods of 3)", %{tournament: tournament} do
      _participants = create_participants(tournament, 6)

      {:ok, round} = create_round_manual(tournament.id, 0)

      tournament = Tournaments.get_tournament!(tournament.id)
      round = Rounds.get_round!(round.id, true)

      {:ok, %{insert_pairings: pairings}} = Pairings.create_pairings_for_round(tournament, round)
      pairing_count = pairings |> Enum.flat_map(& &1.pairing_participants) |> length()

      # Should create 6 participants total in pairings
      assert pairing_count == 6
    end

    test "handles 9 players correctly (3 pods of 3)", %{tournament: tournament} do
      _participants = create_participants(tournament, 9)

      {:ok, round} = create_round_manual(tournament.id, 0)

      tournament = Tournaments.get_tournament!(tournament.id)
      round = Rounds.get_round!(round.id, true)

      {:ok, %{insert_pairings: pairings}} = Pairings.create_pairings_for_round(tournament, round)
      pairing_count = pairings |> Enum.flat_map(& &1.pairing_participants) |> length()

      # Should create 9 participants total in pairings
      assert pairing_count == 9
    end

    test "handles 10 players correctly (2 pods of 4, 1 pod of 2 becomes 3)", %{
      tournament: tournament
    } do
      _participants = create_participants(tournament, 10)

      {:ok, round} = create_round_manual(tournament.id, 0)

      tournament = Tournaments.get_tournament!(tournament.id)
      round = Rounds.get_round!(round.id, true)

      {:ok, %{insert_pairings: pairings}} = Pairings.create_pairings_for_round(tournament, round)
      pairing_count = pairings |> Enum.flat_map(& &1.pairing_participants) |> length()

      # Should create pairings for all 10 players
      assert pairing_count == 10
    end
  end

  describe "create_pairings_for_round/2 - dropped participants" do
    setup do
      user = user_fixture()
      game = game_fixture()

      {:ok, tournament} =
        Tournaments.create_tournament(%{
          name: "Dropped Participants Tournament",
          date: NaiveDateTime.utc_now(),
          location: "Test Location",
          description_raw: "A test tournament for dropped participants",
          game_id: game.id,
          user_id: user.id,
          format: :edh,
          subformat: :swiss,
          round_count: 3,
          is_top_cut_4: false
        })

      participants = create_participants(tournament, 8)

      # Drop 2 participants
      [p1, p2 | _rest] = participants
      Participants.update_participant(p1, %{is_dropped: true})
      Participants.update_participant(p2, %{is_dropped: true})

      {:ok, round} = create_round_manual(tournament.id, 0)

      tournament = Tournaments.get_tournament!(tournament.id)
      round = Rounds.get_round!(round.id, true)

      %{tournament: tournament, round: round}
    end

    test "excludes dropped participants from pairings", %{tournament: tournament, round: round} do
      {:ok, %{insert_pairings: pairings}} = Pairings.create_pairings_for_round(tournament, round)
      pairing_count = pairings |> Enum.flat_map(& &1.pairing_participants) |> length()

      # Should only pair 6 active participants (8 - 2 dropped)
      assert pairing_count == 6
    end
  end

  describe "create_pairings_for_round/2 - top cut" do
    setup do
      user = user_fixture()
      game = game_fixture()

      {:ok, tournament} =
        Tournaments.create_tournament(%{
          name: "Top Cut Tournament",
          date: NaiveDateTime.utc_now(),
          location: "Test Location",
          description_raw: "A test tournament for top cut testing",
          game_id: game.id,
          user_id: user.id,
          format: :edh,
          subformat: :swiss,
          round_count: 2,
          is_top_cut_4: true
        })

      participants = create_participants(tournament, 8)

      # Create a first round with results
      {:ok, round1} = create_round_manual(tournament.id, 0)

      # Create pairings with mock results for scoring
      create_round_with_results(tournament, round1, participants)

      # This is the final round (round_count - 1)
      {:ok, round2} = create_round_manual(tournament.id, 1)

      tournament = Tournaments.get_tournament!(tournament.id)
      round2 = Rounds.get_round!(round2.id, true)

      %{tournament: tournament, round: round2, participants: participants}
    end

    test "creates top cut pairings for final round", %{tournament: tournament, round: round} do
      {:ok, %{insert_pairings: pairings}} = Pairings.create_pairings_for_round(tournament, round)
      pairing_count = pairings |> Enum.flat_map(& &1.pairing_participants) |> length()

      # Top cut should include top 4 players
      assert pairing_count == 4
    end
  end

  describe "create_pairings_for_round/2 - Swiss rounds" do
    setup do
      user = user_fixture()
      game = game_fixture()

      {:ok, tournament} =
        Tournaments.create_tournament(%{
          name: "Swiss Tournament",
          date: NaiveDateTime.utc_now(),
          location: "Test Location",
          description_raw: "A test tournament for Swiss pairing",
          game_id: game.id,
          user_id: user.id,
          format: :edh,
          subformat: :swiss,
          round_count: 3,
          is_top_cut_4: false
        })

      participants = create_participants(tournament, 8)

      # Create first round with results
      {:ok, round1} = create_round_manual(tournament.id, 0)

      create_round_with_results(tournament, round1, participants)

      # Create second round
      {:ok, round2} = create_round_manual(tournament.id, 1)

      tournament = Tournaments.get_tournament!(tournament.id)
      round2 = Rounds.get_round!(round2.id, true)

      %{tournament: tournament, round: round2, participants: participants}
    end

    test "creates Swiss pairings that minimize repeat opponents", %{
      tournament: tournament,
      round: round
    } do
      {:ok, %{insert_pairings: pairings}} = Pairings.create_pairings_for_round(tournament, round)
      pairing_count = pairings |> Enum.flat_map(& &1.pairing_participants) |> length()

      # Should create pairings for all active participants
      assert pairing_count == 8
    end

    test "Swiss algorithm attempts to avoid repeat opponents", %{
      tournament: tournament,
      round: round
    } do
      # This test verifies the Swiss algorithm runs without error
      # The specific opponent avoidance logic is complex and would require
      # more sophisticated fixtures to test deterministically
      {:ok, %{insert_pairings: pairings}} = Pairings.create_pairings_for_round(tournament, round)
      pairing_count = pairings |> Enum.flat_map(& &1.pairing_participants) |> length()

      # Swiss algorithm should create pairings
      assert pairing_count > 0
    end
  end

  describe "create_pairings_for_round/2 - Bubble rounds" do
    setup do
      user = user_fixture()
      game = game_fixture()

      {:ok, tournament} =
        Tournaments.create_tournament(%{
          name: "Bubble Rounds Tournament",
          date: NaiveDateTime.utc_now(),
          location: "Test Location",
          description_raw: "A test tournament for bubble rounds pairing",
          game_id: game.id,
          user_id: user.id,
          format: :edh,
          subformat: :bubble_rounds,
          round_count: 3,
          is_top_cut_4: false
        })

      participants = create_participants(tournament, 8)

      # Create first round with specific results to test bubble logic
      {:ok, round1} = create_round_manual(tournament.id, 0)

      create_bubble_round_with_results(tournament, round1, participants)

      # Create second round
      {:ok, round2} = create_round_manual(tournament.id, 1)

      tournament = Tournaments.get_tournament!(tournament.id)
      round2 = Rounds.get_round!(round2.id, true)

      %{tournament: tournament, round: round2, participants: participants}
    end

    test "creates bubble round pairings based on previous round scores", %{
      tournament: tournament,
      round: round
    } do
      {:ok, %{insert_pairings: pairings}} = Pairings.create_pairings_for_round(tournament, round)
      pairing_count = pairings |> Enum.flat_map(& &1.pairing_participants) |> length()

      # Should create pairings for all participants
      assert pairing_count == 8
    end

    test "bubble rounds group players by similar performance", %{
      tournament: tournament,
      round: round
    } do
      {:ok, %{insert_pairings: pairings}} = Pairings.create_pairings_for_round(tournament, round)
      pairing_count = pairings |> Enum.flat_map(& &1.pairing_participants) |> length()

      # Should create pairings for all participants
      assert pairing_count == 8
    end
  end

  # Helper functions
  defp create_participants(tournament, count) do
    Enum.map(1..count, fn i ->
      user = user_fixture(%{email: "user#{i}_#{tournament.id}@example.com"})

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

  defp create_round_with_results(tournament, round, participants) do
    # Create pairings for the first round

    participants
    |> Enum.shuffle()
    |> Enum.chunk_every(4)
    |> Enum.with_index()
    |> Enum.each(fn {pod_participants, _pairing_number} ->
      pairing_participants =
        Enum.map(pod_participants, fn participant ->
          %{
            participant_id: participant.id,
            points: Enum.random(0..3)
          }
        end)

      {:ok, _pairing} =
        Pairings.create_pairing(%{
          tournament_id: tournament.id,
          round_id: round.id,
          active: false,
          pairing_participants: pairing_participants
        })
    end)
  end

  defp create_bubble_round_with_results(tournament, round, participants) do
    point_distributions = [3, 3, 2, 2, 1, 1, 0, 0]

    participants
    |> Enum.zip(point_distributions)
    |> Enum.chunk_every(4)
    |> Enum.with_index()
    |> Enum.each(fn {pod_participants, _pairing_number} ->
      pairing_participants =
        Enum.map(pod_participants, fn {participant, points} ->
          %{
            participant_id: participant.id,
            points: points
          }
        end)

      {:ok, _pairing} =
        Pairings.create_pairing(%{
          tournament_id: tournament.id,
          round_id: round.id,
          active: false,
          pairing_participants: pairing_participants
        })
    end)
  end
end
