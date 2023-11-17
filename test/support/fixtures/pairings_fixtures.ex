defmodule MtgFriends.PairingsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `MtgFriends.Pairings` context.
  """

  @doc """
  Generate a pairing.
  """
  def pairing_fixture(attrs \\ %{}) do
    {:ok, pairing} =
      attrs
      |> Enum.into(%{

      })
      |> MtgFriends.Pairings.create_pairing()

    pairing
  end
end
