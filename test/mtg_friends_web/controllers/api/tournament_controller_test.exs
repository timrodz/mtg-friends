defmodule MtgFriendsWeb.API.TournamentControllerTest do
  use MtgFriendsWeb.ConnCase

  import MtgFriends.TournamentsFixtures
  import MtgFriends.AccountsFixtures
  import MtgFriends.GamesFixtures

  @create_attrs %{
    name: "some name",
    date: ~N[2023-05-05 12:00:00],
    format: "standard",
    location: "some location",
    description_raw: "some description that is long enough"
  }
  @update_attrs %{
    name: "some updated name",
    date: ~N[2023-05-06 13:00:00],
    format: "edh",
    location: "some updated location",
    description_raw: "some updated description that is long enough"
  }
  @invalid_attrs %{name: nil, date: nil, format: nil, location: nil}

  setup %{conn: conn} do
    user = user_fixture()
    other_user = user_fixture()
    game = game_fixture()
    {:ok, conn: conn, user: user, other_user: other_user, game: game}
  end

  describe "index" do
    test "lists all tournaments", %{conn: conn, user: user, game: game} do
      tournament = tournament_fixture(%{user_id: user.id, game_id: game.id})
      conn = get(conn, ~p"/api/tournaments")
      assert json_response(conn, 200)["data"] != []
      assert Enum.any?(json_response(conn, 200)["data"], fn t -> t["id"] == tournament.id end)
    end

    test "lists tournaments paginated", %{conn: conn, user: user, game: game} do
      for _ <- 1..15 do
        tournament_fixture(%{user_id: user.id, game_id: game.id})
      end

      conn = get(conn, ~p"/api/tournaments?limit=10&page=1")
      assert length(json_response(conn, 200)["data"]) == 10

      conn = get(conn, ~p"/api/tournaments?limit=10&page=2")
      assert length(json_response(conn, 200)["data"]) >= 5
    end
  end

  describe "create tournament" do
    test "renders tournament when data is valid", %{conn: conn, user: user, game: game} do
      token =
        MtgFriends.Accounts.generate_user_session_token(user) |> Base.url_encode64(padding: false)

      conn = put_req_header(conn, "authorization", "Bearer #{token}")

      create_attrs =
        @create_attrs
        |> Map.put(:game_id, game.id)
        |> Map.put(:user_id, user.id)

      conn = post(conn, ~p"/api/tournaments", create_attrs)
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get(conn, ~p"/api/tournaments/#{id}")
      assert json_response(conn, 200)["data"]["id"] == id
    end

    test "renders errors when data is invalid", %{conn: conn, user: user} do
      token =
        MtgFriends.Accounts.generate_user_session_token(user) |> Base.url_encode64(padding: false)

      conn = put_req_header(conn, "authorization", "Bearer #{token}")

      conn = post(conn, ~p"/api/tournaments", @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end

    test "returns 401 when not authenticated", %{conn: conn, game: game} do
      create_attrs = Map.put(@create_attrs, :game_id, game.id)
      conn = post(conn, ~p"/api/tournaments", create_attrs)
      assert response(conn, 401)
    end
  end

  describe "update tournament" do
    setup %{conn: _conn, user: user, game: game} do
      tournament = tournament_fixture(%{user_id: user.id, game_id: game.id})
      {:ok, tournament: tournament}
    end

    test "renders tournament when data is valid", %{
      conn: conn,
      user: user,
      tournament: tournament
    } do
      token =
        MtgFriends.Accounts.generate_user_session_token(user) |> Base.url_encode64(padding: false)

      conn = put_req_header(conn, "authorization", "Bearer #{token}")

      conn = put(conn, ~p"/api/tournaments/#{tournament.id}", @update_attrs)
      id = tournament.id
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get(conn, ~p"/api/tournaments/#{tournament.id}")
      assert json_response(conn, 200)["data"]["name"] == "some updated name"
    end

    test "returns 403 when user is not owner", %{
      conn: conn,
      other_user: other_user,
      tournament: tournament
    } do
      token =
        MtgFriends.Accounts.generate_user_session_token(other_user)
        |> Base.url_encode64(padding: false)

      conn = put_req_header(conn, "authorization", "Bearer #{token}")

      conn = put(conn, ~p"/api/tournaments/#{tournament.id}", @update_attrs)
      # Assuming AuthorizeTournamentOwner returns 403 or 404 or redirects.
      # Since it is an API plug, it likely returns 403.
      assert json_response(conn, 403)
    end
  end

  describe "delete tournament" do
    setup %{user: user, game: game} do
      tournament = tournament_fixture(%{user_id: user.id, game_id: game.id})
      {:ok, tournament: tournament}
    end

    test "deletes chosen tournament", %{conn: conn, user: user, tournament: tournament} do
      token =
        MtgFriends.Accounts.generate_user_session_token(user) |> Base.url_encode64(padding: false)

      conn = put_req_header(conn, "authorization", "Bearer #{token}")

      conn = delete(conn, ~p"/api/tournaments/#{tournament.id}")
      assert response(conn, 204)

      assert_error_sent 404, fn ->
        get(conn, ~p"/api/tournaments/#{tournament.id}")
      end
    end

    test "returns 403 when user is not owner", %{
      conn: conn,
      other_user: other_user,
      tournament: tournament
    } do
      token =
        MtgFriends.Accounts.generate_user_session_token(other_user)
        |> Base.url_encode64(padding: false)

      conn = put_req_header(conn, "authorization", "Bearer #{token}")

      conn = delete(conn, ~p"/api/tournaments/#{tournament.id}")
      assert json_response(conn, 403)
    end
  end
end
