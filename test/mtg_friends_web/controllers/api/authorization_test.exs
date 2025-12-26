defmodule MtgFriendsWeb.API.AuthorizationTest do
  use MtgFriendsWeb.ConnCase

  import MtgFriends.GamesFixtures
  import MtgFriends.AccountsFixtures

  setup %{conn: conn} do
    owner = user_fixture()
    other_user = user_fixture()
    game = game_fixture()

    tournament = MtgFriends.Tournaments.create_tournament(%{
      name: "Auth Test Tournament",
      date: NaiveDateTime.local_now() |> NaiveDateTime.add(3600),
      format: "standard",
      description_raw: "Test Description with enough length for validation rules",
      location: "Local Store",
      user_id: owner.id,
      game_id: game.id
    }) |> elem(1)

    owner_token = MtgFriends.Accounts.generate_user_session_token(owner) |> Base.url_encode64(padding: false)
    other_token = MtgFriends.Accounts.generate_user_session_token(other_user) |> Base.url_encode64(padding: false)

    {:ok, conn: conn, owner_token: owner_token, other_token: other_token, tournament: tournament}
  end

  test "other user cannot update tournament", %{conn: conn, other_token: token, tournament: tournament} do
    conn = put_req_header(conn, "authorization", "Bearer #{token}")
    conn = put(conn, ~p"/api/tournaments/#{tournament.id}", tournament: %{name: "Hacked!"})
    assert json_response(conn, 403)["errors"]["detail"] == "Forbidden"
  end

  test "owner can update tournament", %{conn: conn, owner_token: token, tournament: tournament} do
    conn = put_req_header(conn, "authorization", "Bearer #{token}")
    conn = put(conn, ~p"/api/tournaments/#{tournament.id}", tournament: %{name: "Updated!"})
    assert json_response(conn, 200)["data"]["name"] == "Updated!"
  end
end
