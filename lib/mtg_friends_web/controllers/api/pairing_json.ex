defmodule MtgFriendsWeb.API.PairingJSON do
  alias MtgFriends.Pairings.Pairing

  @doc """
  Renders a single pairing.
  """
  def index(%{pairings: pairings}) do
    %{data: for(pairing <- pairings, do: data(pairing))}
  end

  def show(%{pairing: pairing}) do
    %{data: data(pairing)}
  end

  defp data(%Pairing{} = pairing) do
    %{
      id: pairing.id,
      active: pairing.active,
      winner_id: pairing.winner_id,
      participants: render_participants(pairing)
    }
  end

  def render_participants(pairing) do
    if Ecto.assoc_loaded?(pairing.pairing_participants) do
      Enum.map(pairing.pairing_participants, fn pp ->
        %{
          id: pp.id,
          participant_id: pp.participant_id,
          points: pp.points
        }
      end)
    else
      []
    end
  end
end
