defmodule MtgFriendsWeb.API.RoundJSON do
  alias MtgFriends.Rounds.Round
  alias MtgFriends.Pairings.Pairing

  @doc """
  Renders a single round.
  """
  def show(%{round: round}) do
    %{data: data(round)}
  end

  defp data(%Round{} = round) do
    %{
      id: round.id,
      number: round.number,
      tournament_id: round.tournament_id,
      pairings: for(pairing <- round.pairings || [], do: pairing_data(pairing))
    }
  end

  defp pairing_data(%Pairing{} = pairing) do
    # When preloaded by PairingEngine/Rounds context, participant might be loaded.
    # PairingEngine creates pairings using tournament participants.
    # We should return pairing details including opponent/pod info if possible.
    # Pairings structure is one-per-participant in MtgFriends logic based on context (one participant_id per pairing row).

    data = %{
      id: pairing.id,
      number: pairing.number, # This is the Table Number / Pod Number
      participant_id: pairing.participant_id,
      points: pairing.points,
      winner: pairing.winner
    }

    if Ecto.assoc_loaded?(pairing.participant) do
      Map.put(data, :participant, %{
        id: pairing.participant.id,
        name: pairing.participant.name
      })
    else
      data
    end
  end
end
