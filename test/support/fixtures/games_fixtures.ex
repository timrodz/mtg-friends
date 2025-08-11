defmodule MtgFriends.GamesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `MtgFriends.Games` context.
  """

  @doc """
  Generate a game.
  """
  def game_fixture(attrs \\ %{}) do
    # Use existing seeded games to avoid duplicates
    code = Map.get(attrs, :code, :mtg)
    
    # Try to get existing game first, create only if it doesn't exist
    case MtgFriends.Games.get_game_by_code(code) do
      nil ->
        {:ok, game} =
          attrs
          |> Enum.into(%{
            name: "some name",
            url: "some url",
            code: code
          })
          |> MtgFriends.Games.create_game()
        game
        
      game ->
        game
    end
  end
end
