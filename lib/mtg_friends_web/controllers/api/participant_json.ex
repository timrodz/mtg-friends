defmodule MtgFriendsWeb.API.ParticipantJSON do
  alias MtgFriends.Participants.Participant

  @doc """
  Renders a single participant.
  """
  def index(%{participants: participants}) do
    %{data: for(participant <- participants, do: data(participant))}
  end

  def show(%{participant: participant}) do
    %{data: data(participant)}
  end

  def data(%Participant{} = participant) do
    %{
      id: participant.id,
      name: participant.name,
      points: participant.points,
      decklist: participant.decklist,
      is_tournament_winner: participant.is_tournament_winner,
      is_dropped: participant.is_dropped
    }
  end
end
