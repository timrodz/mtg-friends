defmodule MtgFriendsWeb.API.TournamentFlowTest do
  use MtgFriendsWeb.ConnCase

  import MtgFriends.GamesFixtures
  import MtgFriends.AccountsFixtures

  setup %{conn: conn} do
    user = user_fixture()
    game = game_fixture()

    token =
      MtgFriends.Accounts.generate_user_session_token(user) |> Base.url_encode64(padding: false)

    conn = put_req_header(conn, "authorization", "Bearer #{token}")
    {:ok, conn: conn, user: user, game: game}
  end

  test "complete 16 person tournament flow", %{conn: conn, user: user, game: game} do
    # 1. Create Tournament
    conn =
      post(conn, ~p"/api/tournaments",
        name: "API Test Tournament",
        # Future date
        date: NaiveDateTime.local_now() |> NaiveDateTime.add(3600),
        format: "standard",
        description_raw: "Test Description with enough length for validation rules",
        location: "Local Store",
        user_id: user.id,
        game_id: game.id
      )

    assert %{"id" => tournament_id} = json_response(conn, 201)["data"]

    # 2. Add 16 Participants
    participants = for i <- 1..16, do: "Player #{i}"

    participant_ids =
      for name <- participants do
        conn =
          post(conn, ~p"/api/tournaments/#{tournament_id}/participants",
            name: name,
            decklist: "Deck #{name}"
          )

        data = json_response(conn, 201)["data"]
        assert data["name"] == name
        data["id"]
      end

    # 3. Create Round 1
    # POST /api/tournaments/:id/rounds
    conn = post(conn, ~p"/api/tournaments/#{tournament_id}/rounds", %{number: 0})
    round_data = json_response(conn, 201)["data"]
    round_id = round_data["id"]

    # Manual Pairing Construction for Round 1
    # Pair participants into matches (tables)
    participant_ids
    |> Enum.chunk_every(2)
    |> Enum.with_index(1)
    |> Enum.each(fn {chunk, table_number} ->
      assert length(chunk) <= 2

      for p_id <- chunk do
        post(conn, ~p"/api/tournaments/#{tournament_id}/rounds/#{round_id}/pairings",
          participant_id: p_id,
          number: table_number,
          active: true,
          points: 0
        )
      end
    end)

    # Refresh round data to verify pairings and get pairing objects
    conn = get(conn, ~p"/api/tournaments/#{tournament_id}/rounds/#{round_id}")
    round_data = json_response(conn, 200)["data"]

    assert round_data["number"] == 0
    assert length(round_data["pairings"]) == 16

    pairings = round_data["pairings"]

    # 4. Submit Results
    grouped_pairings = Enum.group_by(pairings, fn p -> p["number"] end)
    assert map_size(grouped_pairings) == 8

    for {_table, table_pairings} <- grouped_pairings do
      # For simplicity: first player wins, others lose
      table_pairings
      |> Enum.with_index()
      |> Enum.each(fn {pairing, index} ->
        points = if index == 0, do: 3, else: 0
        winner = if index == 0, do: true, else: false

        conn =
          put(
            conn,
            ~p"/api/tournaments/#{tournament_id}/rounds/#{round_id}/pairings/#{pairing["id"]}",
            %{points: points, winner: winner, active: false}
          )

        assert json_response(conn, 200)["data"]["points"] == points
      end)
    end

    # 5. Create Round 2
    conn = post(conn, ~p"/api/tournaments/#{tournament_id}/rounds", %{number: 1})
    round_2_data = json_response(conn, 201)["data"]
    round_2_id = round_2_data["id"]

    # Manual Pairing Construction for Round 2 (mock pairing logic: same pairings for simplicity in test)
    participant_ids
    |> Enum.chunk_every(2)
    |> Enum.with_index(1)
    |> Enum.each(fn {chunk, table_number} ->
      assert length(chunk) <= 2

      for p_id <- chunk do
        post(conn, ~p"/api/tournaments/#{tournament_id}/rounds/#{round_2_id}/pairings",
          participant_id: p_id,
          number: table_number,
          active: true,
          points: 0
        )
      end
    end)

    # Refresh Round 2
    conn = get(conn, ~p"/api/tournaments/#{tournament_id}/rounds/#{round_2_id}")
    round_2_data = json_response(conn, 200)["data"]

    assert round_2_data["number"] == 1
    assert length(round_2_data["pairings"]) == 16
  end
end
