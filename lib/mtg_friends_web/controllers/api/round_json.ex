defmodule MtgFriendsWeb.API.RoundJSON do
  alias MtgFriends.Rounds.Round

  @doc """
  Renders a single round.
  """
  def index(%{rounds: rounds}) do
    %{data: for(round <- rounds, do: data(round))}
  end

  def show(%{round: round}) do
    %{data: data(round)}
  end

  def data(%Round{} = round) do
    %{
      id: round.id,
      number: round.number,
      status: round.status,
      started_at: round.started_at,
      pairings:
        if(Ecto.assoc_loaded?(round.pairings),
          do:
            for(
              pairing <- round.pairings,
              do: MtgFriendsWeb.API.PairingJSON.render_participants(pairing)
            ),
          else: []
        )
    }
  end
end
