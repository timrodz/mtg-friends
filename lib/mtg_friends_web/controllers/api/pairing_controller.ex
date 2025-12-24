defmodule MtgFriendsWeb.API.PairingController do
  use MtgFriendsWeb, :controller

  alias MtgFriends.Pairings
  alias MtgFriends.Pairings.Pairing

  action_fallback MtgFriendsWeb.FallbackController

  # Update result for a pairing (e.g. setting points or winner)
  # BUT `Pairings.update_pairings` in context is designed for form params and POD update.
  # It takes "input-points-participant-ID" keys.
  # We should probably expose a cleaner API and map it, OR expose `update` for a single pairing struct.
  # `Pairings.update_pairing/2` exists for single pairing update using changeset.

  def update(conn, %{"id" => id, "pairing" => pairing_params}) do
    pairing = Pairings.get_pairing!(id)

    with {:ok, %Pairing{} = pairing} <- Pairings.update_pairing(pairing, pairing_params) do
      render(conn, :show, pairing: pairing)
    end
  end
end
