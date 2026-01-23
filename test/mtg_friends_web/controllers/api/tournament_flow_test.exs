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
    conn = post(conn, ~p"/api/tournaments/#{tournament_id}/rounds", %{number: 0})
    round_data = json_response(conn, 201)["data"]
    round_id = round_data["id"]

    # Manual Pairing Construction for Round 1
    pairing_ids =
      participant_ids
      |> Enum.chunk_every(2)
      |> Enum.map(fn chunk ->
        pairing_participants =
          Enum.map(chunk, fn p_id ->
            %{participant_id: p_id, points: 0}
          end)

        conn =
          post(conn, ~p"/api/tournaments/#{tournament_id}/rounds/#{round_id}/pairings", %{
            pairing_participants: pairing_participants,
            active: true
          })

        json_response(conn, 201)["data"]["id"]
      end)

    # Refresh round data
    conn = get(conn, ~p"/api/tournaments/#{tournament_id}/rounds/#{round_id}")
    round_data = json_response(conn, 200)["data"]

    assert round_data["number"] == 0
    assert length(round_data["pairings"]) == 8

    # 4. Submit Results
    for pairing_id <- pairing_ids do
      conn =
        get(conn, ~p"/api/tournaments/#{tournament_id}/rounds/#{round_id}/pairings/#{pairing_id}")

      pairing_data = json_response(conn, 200)["data"]
      [pp1, pp2] = pairing_data["participants"]

      # First player wins (3 pts), second loses (0 pts)
      conn =
        put(
          conn,
          ~p"/api/tournaments/#{tournament_id}/rounds/#{round_id}/pairings/#{pairing_id}",
          %{
            winner_id: pp1["participant_id"],
            active: false,
            pairing_participants: [
              %{id: pp1["id"], points: 3},
              %{id: pp2["id"], points: 0}
            ]
          }
        )

      data = json_response(conn, 200)["data"]
      assert data["winner_id"] == pp1["participant_id"]
    end

    # 5. Create Round 2
    conn = post(conn, ~p"/api/tournaments/#{tournament_id}/rounds", %{number: 1})
    round_2_data = json_response(conn, 201)["data"]
    round_2_id = round_2_data["id"]

    # Manual Pairing Construction for Round 2
    participant_ids
    |> Enum.chunk_every(2)
    |> Enum.each(fn chunk ->
      pairing_participants =
        Enum.map(chunk, fn p_id ->
          %{participant_id: p_id, points: 0}
        end)

      post(conn, ~p"/api/tournaments/#{tournament_id}/rounds/#{round_2_id}/pairings", %{
        pairing_participants: pairing_participants,
        active: true
      })
    end)

    # Refresh Round 2
    conn = get(conn, ~p"/api/tournaments/#{tournament_id}/rounds/#{round_2_id}")
    round_2_data = json_response(conn, 200)["data"]

    assert round_2_data["number"] == 1
    assert length(round_2_data["pairings"]) == 8
  end
end
