defmodule MtgFriends.ParticipantsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `MtgFriends.Participants` context.
  """

  @doc """
  Generate a participant.
  """
  def participant_fixture(attrs \\ %{}) do
    {:ok, participant} =
      attrs
      |> Enum.into(%{
        decklist: "some decklist",
        name: "some name",
        points: 42
      })
      |> MtgFriends.Participants.create_participant()

    participant
  end
end
