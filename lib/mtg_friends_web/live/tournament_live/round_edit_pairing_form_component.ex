defmodule MtgFriendsWeb.TournamentLive.RoundEditPairingFormComponent do
  use MtgFriendsWeb, :live_component

  require Logger

  alias MtgFriends.Pairings
  alias MtgFriends.Tournaments
  alias MtgFriends.Rounds

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header class="mb-4">
        {@title}
        <:subtitle>
          If your pod has finished, give points to players based on their performance
        </:subtitle>
      </.header>

      <.simple_form for={@form} id={"edit-pairing-#{@id}"} phx-target={@myself} phx-submit="save">
        <input type="hidden" name="pairing-number" value={@id} />

        <div class="grid grid-cols-1 gap-2 w-full md:w-3/4">
          <div
            :for={p <- @form.params["participants"]}
            class="flex justify-between items-center"
            id={"pairing-participant-#{p.id}"}
          >
            <p class="font-semibold">{p.name}</p>
            <div class="flex items-center gap-2">
              <p>Points:</p>
              <.input
                name={"input-points-participant-#{p.id}"}
                value={p.points}
                type="number"
                max="10"
                min="0"
                class="w-[8rem]"
              />
            </div>
          </div>
        </div>
        <:actions>
          <.button phx-disable-with="Saving..." variant="primary">
            <.icon name="hero-check-solid" /> Submit changes
          </.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(assigns, socket) do
    {
      :ok,
      socket
      |> assign(assigns)
    }
  end

  @impl true
  def handle_event(
        "save",
        params,
        socket
      ) do
    %{tournament_id: tournament_id, round_id: round_id} =
      socket.assigns

    {:ok, _} = Pairings.update_pairings(tournament_id, round_id, params)

    tournament = Tournaments.get_tournament_simple!(tournament_id)
    round = Rounds.get_round!(round_id)

    # Check logic via Rounds context
    case Rounds.check_and_finalize(round, tournament) do
      {:ok, _round, :tournament_finished} ->
        {:noreply,
         socket
         |> put_flash(:success, "Last pod updated successfully - Tournament has finished!")
         |> push_navigate(to: ~p"/tournaments/#{tournament.id}")}

      {:ok, _round, _status} ->
        {:noreply,
         socket
         |> put_flash(:success, "Pod updated successfully")
         |> push_navigate(to: socket.assigns.patch)}
    end
  end
end
