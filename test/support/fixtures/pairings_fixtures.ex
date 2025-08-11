defmodule MtgFriends.PairingsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `MtgFriends.Pairings` context.
  """

  import MtgFriends.TournamentsFixtures
  import MtgFriends.RoundsFixtures
  import MtgFriends.ParticipantsFixtures

  @doc """
  Generate a pairing.
  """
  def pairing_fixture(attrs \\ %{}) do
    tournament = Map.get(attrs, :tournament) || tournament_fixture()
    round = Map.get(attrs, :round) || round_fixture(%{tournament: tournament})
    participant = Map.get(attrs, :participant) || participant_fixture(%{tournament: tournament})

    {:ok, pairing} =
      attrs
      |> Enum.into(%{
        number: 0,
        tournament_id: tournament.id,
        round_id: round.id,
        participant_id: participant.id,
        points: 0,
        winner: false,
        active: false
      })
      |> MtgFriends.Pairings.create_pairing()

    pairing
  end
end
