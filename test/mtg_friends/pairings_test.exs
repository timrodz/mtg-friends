defmodule MtgFriends.PairingsTest do
  use MtgFriends.DataCase

  alias MtgFriends.Pairings

  describe "pairings" do
    alias MtgFriends.Pairings.Pairing

    import MtgFriends.PairingsFixtures
    import MtgFriends.TournamentsFixtures
    import MtgFriends.RoundsFixtures
    import MtgFriends.ParticipantsFixtures

    # invalid: missing required relation IDs (though changeset validates existence, nil check likely)
    @invalid_attrs %{tournament_id: nil}

    test "list_pairings/0 returns all pairings" do
      pairing = pairing_fixture()
      # list_pairings preloads pairing_participants
      assert length(Pairings.list_pairings()) == 1
      assert hd(Pairings.list_pairings()).id == pairing.id
    end

    test "get_pairing!/1 returns the pairing with given id" do
      pairing = pairing_fixture()
      # get_pairing! preloads pairing_participants
      fetched_pairing = Pairings.get_pairing!(pairing.id)
      assert fetched_pairing.id == pairing.id
    end

    test "create_pairing/1 with valid data creates a pairing with participants" do
      tournament = tournament_fixture()
      round = round_fixture(%{tournament: tournament})
      participant = participant_fixture(%{tournament: tournament})

      valid_attrs = %{
        tournament_id: tournament.id,
        round_id: round.id,
        active: true,
        pairing_participants: [
          %{participant_id: participant.id, points: 2}
        ]
      }

      assert {:ok, %Pairing{} = pairing} = Pairings.create_pairing(valid_attrs)
      assert length(pairing.pairing_participants) == 1
      assert hd(pairing.pairing_participants).points == 2
    end

    test "create_pairing/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Pairings.create_pairing(@invalid_attrs)
    end

    test "update_pairing/2 with valid data updates the pairing" do
      pairing = pairing_fixture()
      update_attrs = %{active: false}

      assert {:ok, %Pairing{} = updated_pairing} = Pairings.update_pairing(pairing, update_attrs)
      assert updated_pairing.active == false
    end

    # Note: Updating points/winner happens via update_pairings (plural) context function
    # or by updating individual pairing_participants. Pairings.update_pairing updates the pairing wrapper.
    # To test points update via update_pairing, we would need to pass nested params if cast_assoc allows update.
    # But usually update_pairing is used for simple field updates on pairing.

    test "update_pairing/2 with invalid data returns error changeset" do
      pairing = pairing_fixture()
      assert {:error, %Ecto.Changeset{}} = Pairings.update_pairing(pairing, @invalid_attrs)
      assert pairing.id == Pairings.get_pairing!(pairing.id).id
    end

    test "delete_pairing/1 deletes the pairing" do
      pairing = pairing_fixture()
      assert {:ok, %Pairing{}} = Pairings.delete_pairing(pairing)
      assert_raise Ecto.NoResultsError, fn -> Pairings.get_pairing!(pairing.id) end
    end

    test "change_pairing/1 returns a pairing changeset" do
      pairing = pairing_fixture()
      assert %Ecto.Changeset{} = Pairings.change_pairing(pairing)
    end
  end
end
