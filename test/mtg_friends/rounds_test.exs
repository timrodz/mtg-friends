defmodule MtgFriends.RoundsTest do
  use MtgFriends.DataCase

  alias MtgFriends.Rounds

  describe "rounds" do
    alias MtgFriends.Rounds.Round

    import MtgFriends.RoundsFixtures
    import MtgFriends.TournamentsFixtures

    @invalid_attrs %{tournament_id: nil, number: nil}

    test "list_rounds/0 returns all rounds" do
      round = round_fixture()
      assert Rounds.list_rounds() == [round]
    end

    test "get_round!/1 returns the round with given id" do
      round = round_fixture()
      assert Rounds.get_round!(round.id) == round
    end

    test "create_round/1 with valid data creates a round" do
      tournament = tournament_fixture()
      valid_attrs = %{tournament_id: tournament.id, number: 1, status: :inactive}

      assert {:ok, %Round{} = _round} = Rounds.create_round(valid_attrs)
    end

    test "create_round/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Rounds.create_round(@invalid_attrs)
    end

    test "update_round/2 with valid data updates the round" do
      round = round_fixture()
      update_attrs = %{status: :active}

      assert {:ok, %Round{} = _round} = Rounds.update_round(round, update_attrs)
    end

    test "update_round/2 with invalid data returns error changeset" do
      round = round_fixture()
      assert {:ok, %Round{}} = Rounds.update_round(round, %{status: :inactive})
      assert round.id == Rounds.get_round!(round.id).id
    end

    test "delete_round/1 deletes the round" do
      round = round_fixture()
      assert {:ok, %Round{}} = Rounds.delete_round(round)
      assert_raise Ecto.NoResultsError, fn -> Rounds.get_round!(round.id) end
    end

    test "change_round/1 returns a round changeset" do
      round = round_fixture()
      assert %Ecto.Changeset{} = Rounds.change_round(round)
    end

    test "check_and_finalize/2 updates participant scores and win rates" do
      tournament = tournament_fixture()
      p1 = MtgFriends.ParticipantsFixtures.participant_fixture(%{tournament_id: tournament.id})
      p2 = MtgFriends.ParticipantsFixtures.participant_fixture(%{tournament_id: tournament.id})

      {:ok, round} =
        Rounds.create_round(%{tournament_id: tournament.id, number: 1, status: :active})

      # Create a pairing for p1 and p2
      {:ok, pairing} =
        MtgFriends.Pairings.create_pairing(%{
          tournament_id: tournament.id,
          round_id: round.id,
          active: false,
          pairing_participants: [
            %{participant_id: p1.id, points: 3},
            %{participant_id: p2.id, points: 0}
          ]
        })

      # Set winner to p1's pairing_participant
      # Need to reload to get the auto-generated IDs of pairing_participants
      pairing = MtgFriends.Repo.preload(pairing, :pairing_participants)

      {:ok, _} = MtgFriends.Pairings.update_pairing(pairing, %{winner_id: p1.id})

      # check_and_finalize
      {:ok, _round, _status} = Rounds.check_and_finalize(round, tournament)

      p1_updated = MtgFriends.Participants.get_participant!(p1.id)
      p2_updated = MtgFriends.Participants.get_participant!(p2.id)

      assert p1_updated.points == 3
      assert p1_updated.win_rate == 100.0

      assert p2_updated.points == 0
      assert p2_updated.win_rate == 0.0
    end
  end
end
