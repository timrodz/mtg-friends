defmodule MtgFriendsWeb.API.ParticipantControllerTest do
  use MtgFriendsWeb.ConnCase

  import MtgFriends.TournamentsFixtures
  import MtgFriends.AccountsFixtures
  import MtgFriends.ParticipantsFixtures
  import MtgFriends.GamesFixtures

  @create_attrs %{
    name: "some participant",
    decklist: "some decklist"
  }
  @update_attrs %{
    name: "some updated participant",
    decklist: "some updated decklist"
  }
  @invalid_attrs %{points: "not-a-number"}

  setup %{conn: conn} do
    user = user_fixture()
    other_user = user_fixture()
    game = game_fixture()
    tournament = tournament_fixture(%{user_id: user.id, game_id: game.id})
    {:ok, conn: conn, user: user, other_user: other_user, tournament: tournament}
  end

  describe "show participant" do
    test "renders participant", %{conn: conn, tournament: tournament} do
      participant = participant_fixture(%{tournament_id: tournament.id})
      conn = get(conn, ~p"/api/tournaments/#{tournament.id}/participants/#{participant.id}")
      assert json_response(conn, 200)["data"]["id"] == participant.id
    end
  end

  describe "create participant" do
    test "renders participant when data is valid", %{
      conn: conn,
      user: user,
      tournament: tournament
    } do
      token =
        MtgFriends.Accounts.generate_user_session_token(user) |> Base.url_encode64(padding: false)

      conn = put_req_header(conn, "authorization", "Bearer #{token}")

      conn =
        post(conn, ~p"/api/tournaments/#{tournament.id}/participants", @create_attrs)

      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get(conn, ~p"/api/tournaments/#{tournament.id}/participants/#{id}")
      assert json_response(conn, 200)["data"]["name"] == "some participant"
    end

    test "renders errors when data is invalid", %{conn: conn, user: user, tournament: tournament} do
      token =
        MtgFriends.Accounts.generate_user_session_token(user) |> Base.url_encode64(padding: false)

      conn = put_req_header(conn, "authorization", "Bearer #{token}")

      conn =
        post(conn, ~p"/api/tournaments/#{tournament.id}/participants", @invalid_attrs)

      assert json_response(conn, 422)["errors"] != %{}
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

      conn =
        post(conn, ~p"/api/tournaments/#{tournament.id}/participants", @create_attrs)

      assert json_response(conn, 403)
    end
  end

  describe "update participant" do
    setup %{tournament: tournament} do
      participant = participant_fixture(%{tournament_id: tournament.id})
      {:ok, participant: participant}
    end

    test "renders participant when data is valid", %{
      conn: conn,
      user: user,
      tournament: tournament,
      participant: participant
    } do
      token =
        MtgFriends.Accounts.generate_user_session_token(user) |> Base.url_encode64(padding: false)

      conn = put_req_header(conn, "authorization", "Bearer #{token}")

      conn =
        put(
          conn,
          ~p"/api/tournaments/#{tournament.id}/participants/#{participant.id}",
          @update_attrs
        )

      id = participant.id
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get(conn, ~p"/api/tournaments/#{tournament.id}/participants/#{participant.id}")
      assert json_response(conn, 200)["data"]["name"] == "some updated participant"
    end

    test "returns 403 when user is not owner", %{
      conn: conn,
      other_user: other_user,
      tournament: tournament,
      participant: participant
    } do
      token =
        MtgFriends.Accounts.generate_user_session_token(other_user)
        |> Base.url_encode64(padding: false)

      conn = put_req_header(conn, "authorization", "Bearer #{token}")

      conn =
        put(
          conn,
          ~p"/api/tournaments/#{tournament.id}/participants/#{participant.id}",
          @update_attrs
        )

      assert json_response(conn, 403)
    end
  end

  describe "delete participant" do
    setup %{tournament: tournament} do
      participant = participant_fixture(%{tournament_id: tournament.id})
      {:ok, participant: participant}
    end

    test "deletes chosen participant", %{
      conn: conn,
      user: user,
      tournament: tournament,
      participant: participant
    } do
      token =
        MtgFriends.Accounts.generate_user_session_token(user) |> Base.url_encode64(padding: false)

      conn = put_req_header(conn, "authorization", "Bearer #{token}")

      conn = delete(conn, ~p"/api/tournaments/#{tournament.id}/participants/#{participant.id}")
      assert response(conn, 204)

      assert_error_sent 404, fn ->
        get(conn, ~p"/api/tournaments/#{tournament.id}/participants/#{participant.id}")
      end
    end

    test "returns 403 when user is not owner", %{
      conn: conn,
      other_user: other_user,
      tournament: tournament,
      participant: participant
    } do
      token =
        MtgFriends.Accounts.generate_user_session_token(other_user)
        |> Base.url_encode64(padding: false)

      conn = put_req_header(conn, "authorization", "Bearer #{token}")

      conn = delete(conn, ~p"/api/tournaments/#{tournament.id}/participants/#{participant.id}")
      assert json_response(conn, 403)
    end
  end
end
