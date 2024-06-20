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
        status: :inactive,
        number: 0,
        started_at: NaiveDateTime.utc_now()
      })
      |> MtgFriends.Rounds.create_round()

    round
  end
end
