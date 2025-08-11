defmodule MtgFriendsWeb.TournamentLiveTest do
  use MtgFriendsWeb.ConnCase

  import Phoenix.LiveViewTest
  import MtgFriends.TournamentsFixtures
  import MtgFriends.AccountsFixtures

  @create_attrs %{
    name: "Test Tournament Name",
    location: "Test Location Here",
    date: ~N[2023-11-02 00:00:00],
    description_raw: "This is a test tournament description for testing purposes"
  }
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

      assert index_live |> element("a", "New Tournament") |> render_click() =~
               "New Tournament"

      assert_patch(index_live, ~p"/tournaments/new")

      assert index_live
             |> form("#tournament-form", tournament: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#tournament-form", tournament: @create_attrs)
             |> render_submit()

      {path, flash} = assert_redirect(index_live)
      assert path =~ ~r/^\/tournaments\/\d+$/
      assert flash["info"] =~ "Tournament created successfully"
    end

    test "updates tournament through modal" do
      user = user_fixture()
      tournament = tournament_fixture(%{user: user})
      conn = log_in_user(build_conn(), user)

      {:ok, _index_live, _html} = live(conn, ~p"/tournaments")

      # Navigate to the edit modal
      {:ok, index_live, _html} = live(conn, ~p"/tournaments/#{tournament}/edit")

      assert index_live
             |> form("#tournament-form", tournament: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#tournament-form", tournament: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/tournaments")

      html = render(index_live)
      assert html =~ "Tournament updated successfully"
      assert html =~ "Updated Location Here"
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

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit"

      assert_patch(show_live, ~p"/tournaments/#{tournament}/show/edit")

      assert show_live
             |> form("#tournament-form", tournament: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#tournament-form", tournament: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/tournaments/#{tournament}")

      html = render(show_live)
      assert html =~ "Tournament updated successfully"
      assert html =~ "Updated Location Here"
    end
  end
end
