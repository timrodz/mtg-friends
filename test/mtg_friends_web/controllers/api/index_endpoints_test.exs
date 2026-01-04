defmodule MtgFriendsWeb.API.IndexEndpointsTest do
  use MtgFriendsWeb.ConnCase

  import MtgFriends.AccountsFixtures
  import MtgFriends.GamesFixtures
  import MtgFriends.TournamentsFixtures
  import MtgFriends.ParticipantsFixtures
  import MtgFriends.RoundsFixtures
  import MtgFriends.PairingsFixtures

  setup %{conn: conn} do
    user = user_fixture()
    game = game_fixture()
    tournament = tournament_fixture(%{user_id: user.id, game_id: game.id})

    token =
      MtgFriends.Accounts.generate_user_session_token(user) |> Base.url_encode64(padding: false)

    conn = put_req_header(conn, "authorization", "Bearer #{token}")
    {:ok, conn: conn, tournament: tournament}
  end

  describe "participants index" do
    test "lists participants for tournament", %{conn: conn, tournament: tournament} do
      participant = participant_fixture(%{tournament: tournament})
      conn = get(conn, ~p"/api/tournaments/#{tournament.id}/participants")
      assert json_response(conn, 200)["data"] != []
      assert Enum.any?(json_response(conn, 200)["data"], fn p -> p["id"] == participant.id end)
    end
  end

  describe "rounds index" do
    test "lists rounds for tournament", %{conn: conn, tournament: tournament} do
      round = round_fixture(%{tournament: tournament, number: 1})
      conn = get(conn, ~p"/api/tournaments/#{tournament.id}/rounds")
      assert json_response(conn, 200)["data"] != []
      assert Enum.any?(json_response(conn, 200)["data"], fn r -> r["id"] == round.id end)
    end
  end

  describe "pairings index" do
    test "lists pairings for tournament", %{conn: conn, tournament: tournament} do
      participant = participant_fixture(%{tournament: tournament})
      round = round_fixture(%{tournament: tournament, number: 1})
      pairing = pairing_fixture(%{tournament: tournament, round: round, participant: participant})

      conn = get(conn, ~p"/api/tournaments/#{tournament.id}/rounds/#{round.id}/pairings")
      assert json_response(conn, 200)["data"] != []
      assert Enum.any?(json_response(conn, 200)["data"], fn p -> p["id"] == pairing.id end)
    end
  end
end
