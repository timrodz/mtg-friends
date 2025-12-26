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

  def update(conn, %{"tournament_id" => _tournament_id, "id" => id, "pairing" => pairing_params}) do
    tournament = conn.assigns.tournament

    with {:ok, pairing} <- Pairings.get_pairing(id),
         {:ok, %Pairing{} = pairing} <- Pairings.update_pairing(pairing, pairing_params) do
      # Check if round is complete and update status
      round = MtgFriends.Rounds.get_round!(pairing.round_id)
      # We ignore the status return here as it's not currently used in the API response
      {:ok, _round, _status} = MtgFriends.Rounds.check_and_finalize(round, tournament)

      render(conn, :show, pairing: pairing)
    end
  end
end
