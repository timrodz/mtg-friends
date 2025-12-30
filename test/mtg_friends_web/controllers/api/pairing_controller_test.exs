defmodule MtgFriendsWeb.API.PairingControllerTest do
  use MtgFriendsWeb.ConnCase

  import MtgFriends.TournamentsFixtures
  import MtgFriends.AccountsFixtures
  import MtgFriends.RoundsFixtures
  import MtgFriends.PairingsFixtures
  import MtgFriends.GamesFixtures
  import MtgFriends.ParticipantsFixtures

  @create_attrs %{
    points: 3,
    active: true,
    winner: true,
    number: 1
    # round_id might be needed if not handled by controller from path
  }
  @update_attrs %{
    points: 1,
    active: false,
    winner: false
  }

  setup %{conn: conn} do
    user = user_fixture()
    other_user = user_fixture()
    game = game_fixture()
    tournament = tournament_fixture(%{user_id: user.id, game_id: game.id})
    round = round_fixture(%{tournament_id: tournament.id})
    participant = participant_fixture(%{tournament_id: tournament.id})

    {:ok,
     conn: conn,
     user: user,
     other_user: other_user,
     tournament: tournament,
     round: round,
     participant: participant}
  end

  describe "show pairing" do
    test "renders pairing", %{conn: conn, tournament: tournament, round: round} do
      pairing = pairing_fixture(%{round_id: round.id, tournament_id: tournament.id})

      conn =
        get(conn, ~p"/api/tournaments/#{tournament.id}/pairings/#{pairing.id}")

      assert json_response(conn, 200)["data"]["id"] == pairing.id
    end
  end

  describe "create pairing" do
    test "renders pairing when data is valid", %{
      conn: conn,
      user: user,
      tournament: tournament,
      round: round,
      participant: participant
    } do
      token =
        MtgFriends.Accounts.generate_user_session_token(user) |> Base.url_encode64(padding: false)

      conn = put_req_header(conn, "authorization", "Bearer #{token}")

      # Creating pairing manually
      # Note: We must ensure round_id is passed if controller doesn't extract it from path,
      # but ideally we test what the route provides.
      # If the controller fails to read round_id from path, this test might fail if we don't include it in body.
      # Let's try including it in body to be safe for a "simple CRUD" endpoint test.
      create_attrs =
        @create_attrs
        |> Map.put(:round_id, round.id)
        |> Map.put(:participant_id, participant.id)

      conn =
        post(
          conn,
          ~p"/api/tournaments/#{tournament.id}/rounds/#{round.id}/pairings",
          create_attrs
        )

      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get(conn, ~p"/api/tournaments/#{tournament.id}/pairings/#{id}")
      assert json_response(conn, 200)["data"]["id"] == id
    end

    test "returns 403 when user is not owner", %{
      conn: conn,
      other_user: other_user,
      tournament: tournament,
      round: round,
      participant: participant
    } do
      token =
        MtgFriends.Accounts.generate_user_session_token(other_user)
        |> Base.url_encode64(padding: false)

      conn = put_req_header(conn, "authorization", "Bearer #{token}")

      create_attrs =
        @create_attrs
        |> Map.put(:round_id, round.id)
        |> Map.put(:participant_id, participant.id)

      conn =
        post(
          conn,
          ~p"/api/tournaments/#{tournament.id}/rounds/#{round.id}/pairings",
          create_attrs
        )

      assert json_response(conn, 403)
    end
  end

  describe "update pairing" do
    setup %{tournament: tournament, round: round} do
      pairing = pairing_fixture(%{round_id: round.id, tournament_id: tournament.id})
      {:ok, pairing: pairing}
    end

    test "renders pairing when data is valid", %{
      conn: conn,
      user: user,
      tournament: tournament,
      round: round,
      pairing: pairing
    } do
      token =
        MtgFriends.Accounts.generate_user_session_token(user) |> Base.url_encode64(padding: false)

      conn = put_req_header(conn, "authorization", "Bearer #{token}")

      conn =
        put(
          conn,
          ~p"/api/tournaments/#{tournament.id}/rounds/#{round.id}/pairings/#{pairing.id}",
          @update_attrs
        )

      id = pairing.id
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn =
        get(conn, ~p"/api/tournaments/#{tournament.id}/pairings/#{pairing.id}")

      assert json_response(conn, 200)["data"]["points"] == 1
    end

    test "returns 403 when user is not owner", %{
      conn: conn,
      other_user: other_user,
      tournament: tournament,
      round: round,
      pairing: pairing
    } do
      token =
        MtgFriends.Accounts.generate_user_session_token(other_user)
        |> Base.url_encode64(padding: false)

      conn = put_req_header(conn, "authorization", "Bearer #{token}")

      conn =
        put(
          conn,
          ~p"/api/tournaments/#{tournament.id}/rounds/#{round.id}/pairings/#{pairing.id}",
          @update_attrs
        )

      assert json_response(conn, 403)
    end
  end

  describe "delete pairing" do
    setup %{tournament: tournament, round: round} do
      pairing = pairing_fixture(%{round_id: round.id, tournament_id: tournament.id})
      {:ok, pairing: pairing}
    end

    test "deletes chosen pairing", %{
      conn: conn,
      user: user,
      tournament: tournament,
      round: round,
      pairing: pairing
    } do
      token =
        MtgFriends.Accounts.generate_user_session_token(user) |> Base.url_encode64(padding: false)

      conn = put_req_header(conn, "authorization", "Bearer #{token}")

      conn =
        delete(
          conn,
          ~p"/api/tournaments/#{tournament.id}/rounds/#{round.id}/pairings/#{pairing.id}"
        )

      assert response(conn, 204)

      assert_error_sent 404, fn ->
        get(conn, ~p"/api/tournaments/#{tournament.id}/pairings/#{pairing.id}")
      end
    end

    test "returns 403 when user is not owner", %{
      conn: conn,
      other_user: other_user,
      tournament: tournament,
      round: round,
      pairing: pairing
    } do
      token =
        MtgFriends.Accounts.generate_user_session_token(other_user)
        |> Base.url_encode64(padding: false)

      conn = put_req_header(conn, "authorization", "Bearer #{token}")

      conn =
        delete(
          conn,
          ~p"/api/tournaments/#{tournament.id}/rounds/#{round.id}/pairings/#{pairing.id}"
        )

      assert json_response(conn, 403)
    end
  end
end
