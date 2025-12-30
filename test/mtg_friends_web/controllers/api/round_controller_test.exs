defmodule MtgFriendsWeb.API.RoundControllerTest do
  use MtgFriendsWeb.ConnCase

  import MtgFriends.TournamentsFixtures
  import MtgFriends.AccountsFixtures
  import MtgFriends.RoundsFixtures
  import MtgFriends.GamesFixtures

  setup %{conn: conn} do
    user = user_fixture()
    other_user = user_fixture()
    game = game_fixture()
    tournament = tournament_fixture(%{user_id: user.id, game_id: game.id})
    {:ok, conn: conn, user: user, other_user: other_user, tournament: tournament}
  end

  describe "show round" do
    test "renders round", %{conn: conn, tournament: tournament} do
      round = round_fixture(%{tournament_id: tournament.id})
      conn = get(conn, ~p"/api/tournaments/#{tournament.id}/rounds/#{round.id}")
      assert json_response(conn, 200)["data"]["id"] == round.id
    end
  end

  describe "create round" do
    test "renders round when data is valid", %{conn: conn, user: user, tournament: tournament} do
      token =
        MtgFriends.Accounts.generate_user_session_token(user) |> Base.url_encode64(padding: false)

      conn = put_req_header(conn, "authorization", "Bearer #{token}")

      conn = post(conn, ~p"/api/tournaments/#{tournament.id}/rounds", %{number: 1})
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get(conn, ~p"/api/tournaments/#{tournament.id}/rounds/#{id}")
      assert json_response(conn, 200)["data"]["id"] == id
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

      conn = post(conn, ~p"/api/tournaments/#{tournament.id}/rounds", %{})
      assert json_response(conn, 403)
    end
  end

  describe "update round" do
    setup %{tournament: tournament} do
      round = round_fixture(%{tournament_id: tournament.id})
      {:ok, round: round}
    end

    test "renders round when data is valid", %{
      conn: conn,
      user: user,
      tournament: tournament,
      round: round
    } do
      token =
        MtgFriends.Accounts.generate_user_session_token(user) |> Base.url_encode64(padding: false)

      conn = put_req_header(conn, "authorization", "Bearer #{token}")

      # Assuming we can update something, maybe just metadata? Or forcing a re-pair?
      # If Round schema has no updateable fields exposed easily, this might be tricky.
      # But checking the controller, it calls Rounds.update_round.

      conn =
        put(conn, ~p"/api/tournaments/#{tournament.id}/rounds/#{round.id}", %{
          number: round.number
        })

      id = round.id
      assert %{"id" => ^id} = json_response(conn, 200)["data"]
    end

    test "returns 403 when user is not owner", %{
      conn: conn,
      other_user: other_user,
      tournament: tournament,
      round: round
    } do
      token =
        MtgFriends.Accounts.generate_user_session_token(other_user)
        |> Base.url_encode64(padding: false)

      conn = put_req_header(conn, "authorization", "Bearer #{token}")

      conn = put(conn, ~p"/api/tournaments/#{tournament.id}/rounds/#{round.id}", %{})
      assert json_response(conn, 403)
    end
  end

  describe "delete round" do
    setup %{tournament: tournament} do
      round = round_fixture(%{tournament_id: tournament.id})
      {:ok, round: round}
    end

    test "deletes chosen round", %{conn: conn, user: user, tournament: tournament, round: round} do
      token =
        MtgFriends.Accounts.generate_user_session_token(user) |> Base.url_encode64(padding: false)

      conn = put_req_header(conn, "authorization", "Bearer #{token}")

      conn = delete(conn, ~p"/api/tournaments/#{tournament.id}/rounds/#{round.id}")
      assert response(conn, 204)

      assert_error_sent 404, fn ->
        get(conn, ~p"/api/tournaments/#{tournament.id}/rounds/#{round.id}")
      end
    end

    test "returns 403 when user is not owner", %{
      conn: conn,
      other_user: other_user,
      tournament: tournament,
      round: round
    } do
      token =
        MtgFriends.Accounts.generate_user_session_token(other_user)
        |> Base.url_encode64(padding: false)

      conn = put_req_header(conn, "authorization", "Bearer #{token}")

      conn = delete(conn, ~p"/api/tournaments/#{tournament.id}/rounds/#{round.id}")
      assert json_response(conn, 403)
    end
  end
end
