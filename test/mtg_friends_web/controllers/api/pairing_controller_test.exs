defmodule MtgFriendsWeb.API.PairingControllerTest do
  use MtgFriendsWeb.ConnCase

  import MtgFriends.TournamentsFixtures
  import MtgFriends.AccountsFixtures

  setup %{conn: conn} do
    user = user_fixture()
    tournament = tournament_fixture(%{user_id: user.id})

    token =
      MtgFriends.Accounts.generate_user_session_token(user) |> Base.url_encode64(padding: false)

    conn = put_req_header(conn, "authorization", "Bearer #{token}")
    {:ok, conn: conn, user: user, tournament: tournament}
  end

  describe "update pairing" do
    test "returns 404 when pairing does not exist", %{conn: conn, tournament: tournament} do
      # assert_error_sent 404, fn ->
      conn =
        put(conn, ~p"/api/tournaments/#{tournament.id}/rounds/#{123}/pairings/#{999_999}",
          pairing: %{points: 3, winner: true, active: false}
        )

      assert json_response(conn, 404)
      # end
    end
  end
end
