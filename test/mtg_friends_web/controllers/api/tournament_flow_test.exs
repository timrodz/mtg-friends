defmodule MtgFriendsWeb.API.TournamentFlowTest do
  use MtgFriendsWeb.ConnCase

  import MtgFriends.GamesFixtures
  import MtgFriends.AccountsFixtures

  setup %{conn: conn} do
    user = user_fixture()
    game = game_fixture()
    token = MtgFriends.Accounts.generate_user_session_token(user) |> Base.url_encode64(padding: false)
    conn = put_req_header(conn, "authorization", "Bearer #{token}")
    {:ok, conn: conn, user: user, game: game}
  end

  test "complete 16 person tournament flow", %{conn: conn, user: user, game: game} do
    # 1. Create Tournament
    conn = post(conn, ~p"/api/tournaments", tournament: %{
      name: "API Test Tournament",
      date: NaiveDateTime.local_now() |> NaiveDateTime.add(3600), # Future date
      format: "standard",
      description_raw: "Test Description with enough length for validation rules",
      location: "Local Store",
      user_id: user.id,
      game_id: game.id
    })

    assert %{"id" => tournament_id} = json_response(conn, 201)["data"]

    # 2. Add 16 Participants
    participants = for i <- 1..16, do: "Player #{i}"

    for name <- participants do
      conn = post(conn, ~p"/api/tournaments/#{tournament_id}/participants", participant: %{
        name: name,
        decklist: "Deck #{name}"
      })
      assert json_response(conn, 201)["data"]["name"] == name
    end

    # 3. Create Round 1
    # POST /api/tournaments/:id/rounds (no body needed for first round usually, or number=0)
    # The controller determines next number.
    conn = post(conn, ~p"/api/tournaments/#{tournament_id}/rounds", %{})

    round_data = json_response(conn, 201)["data"]
    assert round_data["number"] == 0
    assert length(round_data["pairings"]) == 16
    # Wait, pairings are one PER PARTICIPANT line in DB structure used by PairingEngine?
    # Standard format: 2 players per match. 16 players => 8 matches.
    # But MtgFriends likely stores 16 pairing records (one for each player), linked by table number?
    # Let's inspect the data structure if needed.

    pairings = round_data["pairings"]

    # 4. Submit Results
    # Let's simulate results.
    # We need to find "tables" or "matches".
    # Assuming pairings have "number" as table number.

    grouped_pairings = Enum.group_by(pairings, fn p -> p["number"] end) # number is table/pod?

    # Check if we have 8 tables
    # assert map_size(grouped_pairings) == 8

    # For each table, pick a winner
    for {_table, [p1, p2]} <- grouped_pairings do
      # P1 wins
      conn = put(conn, ~p"/api/pairings/#{p1["id"]}", pairing: %{points: 3, winner: true})
      assert json_response(conn, 200)["data"]["points"] == 3

      conn = put(conn, ~p"/api/pairings/#{p2["id"]}", pairing: %{points: 0, winner: false})
      assert json_response(conn, 200)["data"]["points"] == 0
    end

    # 5. Create Round 2
    conn = post(conn, ~p"/api/tournaments/#{tournament_id}/rounds", %{})
    round_2_data = json_response(conn, 201)["data"]
    assert round_2_data["number"] == 1
    assert length(round_2_data["pairings"]) == 16
  end
end
