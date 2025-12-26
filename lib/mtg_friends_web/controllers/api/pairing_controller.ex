defmodule MtgFriendsWeb.API.PairingController do
  use MtgFriendsWeb, :controller

  use OpenApiSpex.ControllerSpecs

  alias MtgFriends.Pairings
  alias MtgFriends.Pairings.Pairing
  alias MtgFriendsWeb.Schemas

  action_fallback MtgFriendsWeb.FallbackController

  tags ["pairings"]

  operation :update,
    summary: "Update pairing result",
    security: [%{"authorization" => []}],
    parameters: [
      tournament_id: [in: :path, description: "Tournament ID", type: :integer],
      id: [in: :path, description: "Pairing ID", type: :integer]
    ],
    request_body: {"Pairing params", "application/json", Schemas.PairingRequest},
    responses: [
      ok: {"Pairing updated", "application/json", Schemas.PairingResponse},
      unprocessable_entity: {"Validation error", "application/json", Schemas.ErrorResponse}
    ]

  # Update result for a pairing (e.g. setting points or winner)
  # BUT `Pairings.update_pairings` in context is designed for form params and POD update.
  # It takes "input-points-participant-ID" keys.
  # We should probably expose a cleaner API and map it, OR expose `update` for a single pairing struct.
  # `Pairings.update_pairing/2` exists for single pairing update using changeset.

  def update(conn, %{"tournament_id" => _tournament_id, "id" => id, "pairing" => pairing_params}) do
    pairing = Pairings.get_pairing!(id)
    tournament = conn.assigns.tournament

    with {:ok, %Pairing{} = pairing} <- Pairings.update_pairing(pairing, pairing_params) do
      # Check if round is complete and update status
      round = MtgFriends.Rounds.get_round!(pairing.round_id)
      {:ok, _round, _status} = MtgFriends.Rounds.check_and_finalize(round, tournament)

      render(conn, :show, pairing: pairing)
    end
  end
end
