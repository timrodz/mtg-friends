defmodule MtgFriends.TournamentsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `MtgFriends.Tournaments` context.
  """

  @doc """
  Generate a tournament.
  """
  def tournament_fixture(attrs \\ %{}) do
    {:ok, tournament} =
      attrs
      |> Enum.into(%{
        date: "some date",
        location: "some location",
        participants: "some participants",
        standings: "some standings"
      })
      |> MtgFriends.Tournaments.create_tournament()

    tournament
  end
end
