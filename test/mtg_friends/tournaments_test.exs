defmodule MtgFriends.TournamentsTest do
  use MtgFriends.DataCase

  alias MtgFriends.Tournaments

  describe "tournaments" do
    alias MtgFriends.Tournaments.Tournament

    import MtgFriends.TournamentsFixtures

    @invalid_attrs %{date: nil, location: nil, participants: nil, standings: nil}

    test "list_tournaments/0 returns all tournaments" do
      tournament = tournament_fixture()
      assert Tournaments.list_tournaments() == [tournament]
    end

    test "get_tournament!/1 returns the tournament with given id" do
      tournament = tournament_fixture()
      assert Tournaments.get_tournament!(tournament.id) == tournament
    end

    test "create_tournament/1 with valid data creates a tournament" do
      valid_attrs = %{date: "some date", location: "some location", participants: "some participants", standings: "some standings"}

      assert {:ok, %Tournament{} = tournament} = Tournaments.create_tournament(valid_attrs)
      assert tournament.date == "some date"
      assert tournament.location == "some location"
      assert tournament.participants == "some participants"
      assert tournament.standings == "some standings"
    end

    test "create_tournament/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Tournaments.create_tournament(@invalid_attrs)
    end

    test "update_tournament/2 with valid data updates the tournament" do
      tournament = tournament_fixture()
      update_attrs = %{date: "some updated date", location: "some updated location", participants: "some updated participants", standings: "some updated standings"}

      assert {:ok, %Tournament{} = tournament} = Tournaments.update_tournament(tournament, update_attrs)
      assert tournament.date == "some updated date"
      assert tournament.location == "some updated location"
      assert tournament.participants == "some updated participants"
      assert tournament.standings == "some updated standings"
    end

    test "update_tournament/2 with invalid data returns error changeset" do
      tournament = tournament_fixture()
      assert {:error, %Ecto.Changeset{}} = Tournaments.update_tournament(tournament, @invalid_attrs)
      assert tournament == Tournaments.get_tournament!(tournament.id)
    end

    test "delete_tournament/1 deletes the tournament" do
      tournament = tournament_fixture()
      assert {:ok, %Tournament{}} = Tournaments.delete_tournament(tournament)
      assert_raise Ecto.NoResultsError, fn -> Tournaments.get_tournament!(tournament.id) end
    end

    test "change_tournament/1 returns a tournament changeset" do
      tournament = tournament_fixture()
      assert %Ecto.Changeset{} = Tournaments.change_tournament(tournament)
    end
  end

  describe "tournaments" do
    alias MtgFriends.Tournaments.Tournament

    import MtgFriends.TournamentsFixtures

    @invalid_attrs %{date: nil, location: nil}

    test "list_tournaments/0 returns all tournaments" do
      tournament = tournament_fixture()
      assert Tournaments.list_tournaments() == [tournament]
    end

    test "get_tournament!/1 returns the tournament with given id" do
      tournament = tournament_fixture()
      assert Tournaments.get_tournament!(tournament.id) == tournament
    end

    test "create_tournament/1 with valid data creates a tournament" do
      valid_attrs = %{date: ~D[2023-11-02], location: "some location"}

      assert {:ok, %Tournament{} = tournament} = Tournaments.create_tournament(valid_attrs)
      assert tournament.date == ~D[2023-11-02]
      assert tournament.location == "some location"
    end

    test "create_tournament/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Tournaments.create_tournament(@invalid_attrs)
    end

    test "update_tournament/2 with valid data updates the tournament" do
      tournament = tournament_fixture()
      update_attrs = %{date: ~D[2023-11-03], location: "some updated location"}

      assert {:ok, %Tournament{} = tournament} = Tournaments.update_tournament(tournament, update_attrs)
      assert tournament.date == ~D[2023-11-03]
      assert tournament.location == "some updated location"
    end

    test "update_tournament/2 with invalid data returns error changeset" do
      tournament = tournament_fixture()
      assert {:error, %Ecto.Changeset{}} = Tournaments.update_tournament(tournament, @invalid_attrs)
      assert tournament == Tournaments.get_tournament!(tournament.id)
    end

    test "delete_tournament/1 deletes the tournament" do
      tournament = tournament_fixture()
      assert {:ok, %Tournament{}} = Tournaments.delete_tournament(tournament)
      assert_raise Ecto.NoResultsError, fn -> Tournaments.get_tournament!(tournament.id) end
    end

    test "change_tournament/1 returns a tournament changeset" do
      tournament = tournament_fixture()
      assert %Ecto.Changeset{} = Tournaments.change_tournament(tournament)
    end
  end

  describe "tournaments" do
    alias MtgFriends.Tournaments.Tournament

    import MtgFriends.TournamentsFixtures

    @invalid_attrs %{active: nil, date: nil, location: nil}

    test "list_tournaments/0 returns all tournaments" do
      tournament = tournament_fixture()
      assert Tournaments.list_tournaments() == [tournament]
    end

    test "get_tournament!/1 returns the tournament with given id" do
      tournament = tournament_fixture()
      assert Tournaments.get_tournament!(tournament.id) == tournament
    end

    test "create_tournament/1 with valid data creates a tournament" do
      valid_attrs = %{active: true, date: ~D[2023-11-02], location: "some location"}

      assert {:ok, %Tournament{} = tournament} = Tournaments.create_tournament(valid_attrs)
      assert tournament.active == true
      assert tournament.date == ~D[2023-11-02]
      assert tournament.location == "some location"
    end

    test "create_tournament/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Tournaments.create_tournament(@invalid_attrs)
    end

    test "update_tournament/2 with valid data updates the tournament" do
      tournament = tournament_fixture()
      update_attrs = %{active: false, date: ~D[2023-11-03], location: "some updated location"}

      assert {:ok, %Tournament{} = tournament} = Tournaments.update_tournament(tournament, update_attrs)
      assert tournament.active == false
      assert tournament.date == ~D[2023-11-03]
      assert tournament.location == "some updated location"
    end

    test "update_tournament/2 with invalid data returns error changeset" do
      tournament = tournament_fixture()
      assert {:error, %Ecto.Changeset{}} = Tournaments.update_tournament(tournament, @invalid_attrs)
      assert tournament == Tournaments.get_tournament!(tournament.id)
    end

    test "delete_tournament/1 deletes the tournament" do
      tournament = tournament_fixture()
      assert {:ok, %Tournament{}} = Tournaments.delete_tournament(tournament)
      assert_raise Ecto.NoResultsError, fn -> Tournaments.get_tournament!(tournament.id) end
    end

    test "change_tournament/1 returns a tournament changeset" do
      tournament = tournament_fixture()
      assert %Ecto.Changeset{} = Tournaments.change_tournament(tournament)
    end
  end
end
