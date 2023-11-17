defmodule MtgFriends.RoundsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `MtgFriends.Rounds` context.
  """

  @doc """
  Generate a round.
  """
  def round_fixture(attrs \\ %{}) do
    {:ok, round} =
      attrs
      |> Enum.into(%{

      })
      |> MtgFriends.Rounds.create_round()

    round
  end
end
