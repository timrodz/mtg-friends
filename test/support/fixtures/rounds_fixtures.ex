defmodule MtgFriends.RoundsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `MtgFriends.Rounds` context.
  """

  import MtgFriends.TournamentsFixtures

  @doc """
  Generate a round.
  """
  def round_fixture(attrs \\ %{}) do
    tournament = Map.get(attrs, :tournament) || tournament_fixture()

    {:ok, round} =
      attrs
      |> Enum.into(%{
        status: :inactive,
        number: 0,
        started_at: NaiveDateTime.utc_now(),
        tournament_id: tournament.id
      })
      |> MtgFriends.Rounds.create_round()

    round
  end
end
