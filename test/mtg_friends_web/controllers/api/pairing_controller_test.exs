defmodule MtgFriendsWeb.API.PairingControllerTest do
  use MtgFriendsWeb.ConnCase

  import MtgFriends.TournamentsFixtures
  import MtgFriends.AccountsFixtures
  import MtgFriends.RoundsFixtures
  import MtgFriends.PairingsFixtures
  import MtgFriends.GamesFixtures
  import MtgFriends.ParticipantsFixtures

  setup %{conn: conn} do
    user = user_fixture()
    other_user = user_fixture()
    game = game_fixture()
    tournament = tournament_fixture(%{user_id: user.id, game_id: game.id})
    round = round_fixture(%{tournament_id: tournament.id})
    participant = participant_fixture(%{tournament_id: tournament.id})

    create_attrs = %{
      active: true,
      winner_id: nil,
      pairing_participants: [
        %{
          participant_id: participant.id,
          points: 1
        }
      ]
    }

    update_attrs = %{
      active: false,
      winner_id: nil,
      pairing_participants: [
        %{
          participant_id: participant.id,
          points: 2
        }
      ]
    }

    {:ok,
     conn: conn,
     user: user,
     other_user: other_user,
     tournament: tournament,
     round: round,
     create_attrs: create_attrs,
     update_attrs: update_attrs,
     participant: participant}
  end

  describe "show pairing" do
    test "renders pairing", %{conn: conn, user: user, tournament: tournament, round: round} do
      token =
        MtgFriends.Accounts.generate_user_session_token(user) |> Base.url_encode64(padding: false)

      conn = put_req_header(conn, "authorization", "Bearer #{token}")
      pairing = pairing_fixture(%{round_id: round.id, tournament_id: tournament.id})

      conn =
        get(conn, ~p"/api/tournaments/#{tournament.id}/rounds/#{round.id}/pairings/#{pairing.id}")

      assert json_response(conn, 200)["data"]["id"] == pairing.id
    end
  end

  describe "create pairing" do
    test "renders pairing when data is valid", %{
      conn: conn,
      user: user,
      tournament: tournament,
      round: round,
      create_attrs: create_attrs,
      participant: _participant
    } do
      token =
        MtgFriends.Accounts.generate_user_session_token(user) |> Base.url_encode64(padding: false)

      conn = put_req_header(conn, "authorization", "Bearer #{token}")

      conn =
        post(
          conn,
          ~p"/api/tournaments/#{tournament.id}/rounds/#{round.id}/pairings",
          create_attrs
        )

      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get(conn, ~p"/api/tournaments/#{tournament.id}/rounds/#{round.id}/pairings/#{id}")
      assert json_response(conn, 200)["data"]["id"] == id
    end

    test "returns 403 when user is not owner", %{
      conn: conn,
      other_user: other_user,
      tournament: tournament,
      round: round,
      create_attrs: create_attrs,
      participant: _participant
    } do
      token =
        MtgFriends.Accounts.generate_user_session_token(other_user)
        |> Base.url_encode64(padding: false)

      conn = put_req_header(conn, "authorization", "Bearer #{token}")

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
    setup %{tournament: tournament, round: round, participant: participant} do
      pairing =
        pairing_fixture(%{
          round_id: round.id,
          tournament_id: tournament.id,
          participant: participant
        })

      {:ok, pairing: pairing}
    end

    test "renders pairing when data is valid", %{
      conn: conn,
      user: user,
      tournament: tournament,
      round: round,
      pairing: pairing,
      update_attrs: update_attrs,
      participant: _participant
    } do
      token =
        MtgFriends.Accounts.generate_user_session_token(user) |> Base.url_encode64(padding: false)

      conn = put_req_header(conn, "authorization", "Bearer #{token}")

      conn =
        put(
          conn,
          ~p"/api/tournaments/#{tournament.id}/rounds/#{round.id}/pairings/#{pairing.id}",
          update_attrs
        )

      id = pairing.id
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn =
        get(conn, ~p"/api/tournaments/#{tournament.id}/rounds/#{round.id}/pairings/#{pairing.id}")

      assert json_response(conn, 200)["data"]["participants"]
             |> Enum.at(0)
             |> Map.get("points") == 2
    end

    test "returns 403 when user is not owner", %{
      conn: conn,
      other_user: other_user,
      tournament: tournament,
      round: round,
      pairing: pairing,
      update_attrs: update_attrs
    } do
      token =
        MtgFriends.Accounts.generate_user_session_token(other_user)
        |> Base.url_encode64(padding: false)

      conn = put_req_header(conn, "authorization", "Bearer #{token}")

      conn =
        put(
          conn,
          ~p"/api/tournaments/#{tournament.id}/rounds/#{round.id}/pairings/#{pairing.id}",
          update_attrs
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
        get(conn, ~p"/api/tournaments/#{tournament.id}/rounds/#{round.id}/pairings/#{pairing.id}")
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
