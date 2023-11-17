defmodule MtgFriends.PairingsTest do
  use MtgFriends.DataCase

  alias MtgFriends.Pairings

  describe "pairings" do
    alias MtgFriends.Pairings.Pairing

    import MtgFriends.PairingsFixtures

    @invalid_attrs %{}

    test "list_pairings/0 returns all pairings" do
      pairing = pairing_fixture()
      assert Pairings.list_pairings() == [pairing]
    end

    test "get_pairing!/1 returns the pairing with given id" do
      pairing = pairing_fixture()
      assert Pairings.get_pairing!(pairing.id) == pairing
    end

    test "create_pairing/1 with valid data creates a pairing" do
      valid_attrs = %{}

      assert {:ok, %Pairing{} = pairing} = Pairings.create_pairing(valid_attrs)
    end

    test "create_pairing/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Pairings.create_pairing(@invalid_attrs)
    end

    test "update_pairing/2 with valid data updates the pairing" do
      pairing = pairing_fixture()
      update_attrs = %{}

      assert {:ok, %Pairing{} = pairing} = Pairings.update_pairing(pairing, update_attrs)
    end

    test "update_pairing/2 with invalid data returns error changeset" do
      pairing = pairing_fixture()
      assert {:error, %Ecto.Changeset{}} = Pairings.update_pairing(pairing, @invalid_attrs)
      assert pairing == Pairings.get_pairing!(pairing.id)
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
