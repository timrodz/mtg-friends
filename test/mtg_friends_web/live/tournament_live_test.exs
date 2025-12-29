defmodule MtgFriendsWeb.TournamentLiveTest do
  use MtgFriendsWeb.ConnCase

  import Phoenix.LiveViewTest
  import MtgFriends.TournamentsFixtures
  import MtgFriends.AccountsFixtures

  # @create_attrs %{
  #   name: "Test Tournament Name",
  #   location: "Test Location Here",
  #   date: ~N[2023-11-02 00:00:00],
  #   description_raw: "This is a test tournament description for testing purposes",
  #   initial_participants: "Player 1\nPlayer 2\nPlayer 3\nPlayer 4"
  # }
  @update_attrs %{
    name: "Updated Tournament Name",
    location: "Updated Location Here",
    date: ~N[2023-11-03 00:00:00],
    description_raw: "This is an updated test tournament description"
  }
  @invalid_attrs %{name: nil, location: nil, date: nil, description_raw: nil}

  defp create_tournament(_) do
    tournament = tournament_fixture()
    %{tournament: tournament}
  end

  describe "Index" do
    setup [:create_tournament]

    test "lists all tournaments", %{conn: conn, tournament: tournament} do
      {:ok, _index_live, html} = live(conn, ~p"/tournaments")

      assert html =~ "Tournaments"
      assert html =~ tournament.location
    end

    test "saves new tournament" do
      user = user_fixture()
      conn = log_in_user(build_conn(), user)

      {:ok, index_live, _html} = live(conn, ~p"/tournaments")

      index_live |> element("a", "Create new tournament") |> render_click()

      assert_patch(index_live, ~p"/tournaments/new")
    end

    test "updates tournament through modal" do
      user = user_fixture()
      tournament = tournament_fixture(%{user: user})
      conn = log_in_user(build_conn(), user)

      {:ok, _index_live, _html} = live(conn, ~p"/tournaments")

      # Navigate to the edit modal
      {:ok, edit_live, _html} = live(conn, ~p"/tournaments/#{tournament}/edit")

      assert edit_live
             |> form("#tournament-form", tournament: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert edit_live
             |> form("#tournament-form", tournament: @update_attrs)
             |> render_submit()

      assert_redirect(edit_live, ~p"/tournaments/#{tournament.id}")
    end
  end

  describe "Show" do
    setup [:create_tournament]

    test "displays tournament", %{conn: conn, tournament: tournament} do
      {:ok, _show_live, html} = live(conn, ~p"/tournaments/#{tournament}")

      assert html =~ tournament.name
      assert html =~ tournament.location
    end

    test "updates tournament within modal" do
      user = user_fixture()
      tournament = tournament_fixture(%{user: user})
      conn = log_in_user(build_conn(), user)

      {:ok, show_live, _html} = live(conn, ~p"/tournaments/#{tournament}")

      show_live |> element("a", "Edit") |> render_click()

      assert_patch(show_live, ~p"/tournaments/#{tournament}/show/edit")
    end
  end
end
