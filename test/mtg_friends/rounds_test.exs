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
  end
end
