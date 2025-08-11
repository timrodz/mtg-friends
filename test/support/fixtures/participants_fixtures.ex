defmodule MtgFriends.ParticipantsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `MtgFriends.Participants` context.
  """

  import MtgFriends.TournamentsFixtures

  @doc """
  Generate a participant.
  """
  def participant_fixture(attrs \\ %{}) do
    tournament = Map.get(attrs, :tournament) || tournament_fixture()

    {:ok, participant} =
      attrs
      |> Enum.into(%{
        decklist: "some decklist",
        name: "some name",
        points: 42,
        tournament_id: tournament.id,
        is_dropped: false,
        is_tournament_winner: false
      })
      |> MtgFriends.Participants.create_participant()

    participant
  end
end
