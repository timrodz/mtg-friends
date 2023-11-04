defmodule MtgFriendsWeb.TournamentLiveTest do
  use MtgFriendsWeb.ConnCase

  import Phoenix.LiveViewTest
  import MtgFriends.TournamentsFixtures

  @create_attrs %{active: true, date: "2023-11-02", location: "some location"}
  @update_attrs %{active: false, date: "2023-11-03", location: "some updated location"}
  @invalid_attrs %{active: false, date: nil, location: nil}

  defp create_tournament(_) do
    tournament = tournament_fixture()
    %{tournament: tournament}
  end

  describe "Index" do
    setup [:create_tournament]

    test "lists all tournaments", %{conn: conn, tournament: tournament} do
      {:ok, _index_live, html} = live(conn, ~p"/tournaments")

      assert html =~ "Listing Tournaments"
      assert html =~ tournament.location
    end

    test "saves new tournament", %{conn: conn} do
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

      assert_patch(index_live, ~p"/tournaments")

      html = render(index_live)
      assert html =~ "Tournament created successfully"
      assert html =~ "some location"
    end

    test "updates tournament in listing", %{conn: conn, tournament: tournament} do
      {:ok, index_live, _html} = live(conn, ~p"/tournaments")

      assert index_live |> element("#tournaments-#{tournament.id} a", "Edit") |> render_click() =~
               "Edit Tournament"

      assert_patch(index_live, ~p"/tournaments/#{tournament}/edit")

      assert index_live
             |> form("#tournament-form", tournament: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#tournament-form", tournament: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/tournaments")

      html = render(index_live)
      assert html =~ "Tournament updated successfully"
      assert html =~ "some updated location"
    end

    test "deletes tournament in listing", %{conn: conn, tournament: tournament} do
      {:ok, index_live, _html} = live(conn, ~p"/tournaments")

      assert index_live |> element("#tournaments-#{tournament.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#tournaments-#{tournament.id}")
    end
  end

  describe "Show" do
    setup [:create_tournament]

    test "displays tournament", %{conn: conn, tournament: tournament} do
      {:ok, _show_live, html} = live(conn, ~p"/tournaments/#{tournament}")

      assert html =~ "Show Tournament"
      assert html =~ tournament.location
    end

    test "updates tournament within modal", %{conn: conn, tournament: tournament} do
      {:ok, show_live, _html} = live(conn, ~p"/tournaments/#{tournament}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Tournament"

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
      assert html =~ "some updated location"
    end
  end
end
