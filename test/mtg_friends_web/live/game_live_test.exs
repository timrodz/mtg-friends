defmodule MtgFriendsWeb.GameLiveTest do
  use MtgFriendsWeb.ConnCase

  import Phoenix.LiveViewTest
  import MtgFriends.GamesFixtures
  import MtgFriends.AccountsFixtures

  @create_attrs %{name: "some name", url: "some url"}
  @update_attrs %{name: "some updated name", url: "some updated url"}
  @invalid_attrs %{name: nil, url: nil}

  defp create_game(_) do
    game = game_fixture()
    %{game: game}
  end

  defp login_admin(%{conn: conn}) do
    admin_user = user_fixture(%{admin: true})
    %{conn: log_in_user(conn, admin_user), admin_user: admin_user}
  end

  describe "Index" do
    setup [:create_game, :login_admin]

    test "lists all games", %{conn: conn, game: game} do
      {:ok, _index_live, html} = live(conn, ~p"/admin/games")

      assert html =~ "Listing Games"
      assert html =~ game.name
    end

    test "saves new game", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/admin/games")

      assert index_live |> element("a", "New Game") |> render_click() =~
               "New Game"

      assert_patch(index_live, ~p"/admin/games/new")

      assert index_live
             |> form("#game-form", game: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#game-form", game: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/admin/games")

      html = render(index_live)
      assert html =~ "Game created successfully"
      assert html =~ "some name"
    end

    test "updates game in listing", %{conn: conn, game: game} do
      {:ok, index_live, _html} = live(conn, ~p"/admin/games")

      assert index_live |> element("#games-#{game.id} a", "Edit") |> render_click() =~
               "Edit Game"

      assert_patch(index_live, ~p"/admin/games/#{game}/edit")

      assert index_live
             |> form("#game-form", game: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#game-form", game: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/admin/games")

      html = render(index_live)
      assert html =~ "Game updated successfully"
      assert html =~ "some updated name"
    end

    test "deletes game in listing", %{conn: conn, game: game} do
      {:ok, index_live, _html} = live(conn, ~p"/admin/games")

      assert index_live |> element("#games-#{game.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#games-#{game.id}")
    end
  end

  describe "Show" do
    setup [:create_game, :login_admin]

    test "displays game", %{conn: conn, game: game} do
      {:ok, _show_live, html} = live(conn, ~p"/admin/games/#{game}")

      assert html =~ "Show Game"
      assert html =~ game.name
    end

    test "updates game within modal", %{conn: conn, game: game} do
      {:ok, show_live, _html} = live(conn, ~p"/admin/games/#{game}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Game"

      assert_patch(show_live, ~p"/admin/games/#{game}/show/edit")

      assert show_live
             |> form("#game-form", game: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#game-form", game: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/admin/games/#{game}")

      html = render(show_live)
      assert html =~ "Game updated successfully"
      assert html =~ "some updated name"
    end
  end
end
