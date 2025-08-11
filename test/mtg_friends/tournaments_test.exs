defmodule MtgFriends.TournamentsTest do
  use MtgFriends.DataCase

  alias MtgFriends.Tournaments

  describe "tournaments" do
    alias MtgFriends.Tournaments.Tournament

    import MtgFriends.TournamentsFixtures
    import MtgFriends.AccountsFixtures
    import MtgFriends.GamesFixtures

    @invalid_attrs %{name: nil, location: nil, date: nil, description_raw: nil, user_id: nil, game_id: nil}

    test "list_tournaments/0 returns all tournaments" do
      tournament = tournament_fixture()
      assert Tournaments.list_tournaments() == [tournament]
    end

    test "get_tournament!/1 returns the tournament with given id" do
      tournament = tournament_fixture()
      fetched = Tournaments.get_tournament!(tournament.id)
      assert fetched.id == tournament.id
      assert fetched.name == tournament.name
    end

    test "create_tournament/1 with valid data creates a tournament" do
      user = user_fixture()
      game = game_fixture()
      valid_attrs = %{
        name: "Test Tournament Name",
        location: "Test Location Here",
        date: ~N[2025-08-15 10:00:00],
        description_raw: "This is a test tournament description for testing purposes",
        user_id: user.id,
        game_id: game.id
      }

      assert {:ok, %Tournament{} = tournament} = Tournaments.create_tournament(valid_attrs)
      assert tournament.name == "Test Tournament Name"
      assert tournament.location == "Test Location Here"
      assert tournament.date == ~N[2025-08-15 10:00:00]
      assert tournament.description_raw == "This is a test tournament description for testing purposes"
    end

    test "create_tournament/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Tournaments.create_tournament(@invalid_attrs)
    end

    test "update_tournament/2 with valid data updates the tournament" do
      tournament = tournament_fixture()

      update_attrs = %{
        name: "Updated Tournament Name",
        location: "Updated Location Here",
        date: ~N[2025-08-16 15:00:00],
        description_raw: "This is an updated test tournament description"
      }

      assert {:ok, %Tournament{} = tournament} =
               Tournaments.update_tournament(tournament, update_attrs)

      assert tournament.name == "Updated Tournament Name"
      assert tournament.location == "Updated Location Here"
      assert tournament.date == ~N[2025-08-16 15:00:00]
      assert tournament.description_raw == "This is an updated test tournament description"
    end

    test "update_tournament/2 with invalid data returns error changeset" do
      tournament = tournament_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Tournaments.update_tournament(tournament, @invalid_attrs)

      fetched = Tournaments.get_tournament!(tournament.id)
      assert fetched.name == tournament.name
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
