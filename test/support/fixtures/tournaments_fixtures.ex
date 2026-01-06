defmodule MtgFriends.TournamentsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `MtgFriends.Tournaments` context.
  """

  import MtgFriends.AccountsFixtures
  import MtgFriends.GamesFixtures

  @doc """
  Generate a tournament.
  """
  def tournament_fixture(attrs \\ %{}) do
    user = Map.get(attrs, :user) || user_fixture()
    game = Map.get(attrs, :game) || game_fixture()

    {:ok, tournament} =
      attrs
      |> Enum.into(%{
        name: "My Tournament",
        date: NaiveDateTime.utc_now(),
        location: "Test Location",
        description_raw: "A test tournament description",
        user_id: user.id,
        game_id: game.id,
        format: :edh,
        subformat: :swiss,
        round_count: 3
      })
      |> MtgFriends.Tournaments.create_tournament()

    tournament
  end
end
