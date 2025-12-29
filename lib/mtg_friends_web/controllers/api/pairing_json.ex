defmodule MtgFriendsWeb.API.PairingJSON do
  alias MtgFriends.Pairings.Pairing

  @doc """
  Renders a single pairing.
  """
  def show(%{pairing: pairing}) do
    %{data: data(pairing)}
  end

  defp data(%Pairing{} = pairing) do
    %{
      id: pairing.id,
      participant_id: pairing.participant_id,
      number: pairing.number,
      points: pairing.points,
      winner: pairing.winner
    }
  end
end
