defmodule MtgFriendsWeb.TournamentLive.RoundEditFormComponent do
  alias MtgFriends.Rounds
  use MtgFriendsWeb, :live_component

  alias MtgFriends.Pairings

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>Update this pod when you have all the results</:subtitle>
      </.header>

      <.simple_form for={@form} id={"edit-pairing-#{@id}"} phx-target={@myself} phx-submit="save">
        <input type="hidden" name="pairing-number" value={@id} />

        <div class="grid grid-cols-1 gap-2 w-full md:w-3/4">
          <div
            :for={p <- @form.params["participants"]}
            class="flex justify-between items-center"
            id={"pairing-participant-#{p.id}"}
          >
            <p class="font-semibold"><%= p.name %></p>
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
          <.button phx-disable-with="Saving...">Update pod results</.button>
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
    %{tournament_id: tournament_id, round_id: round_id} = socket.assigns

    case Pairings.update_pairings(tournament_id, round_id, params) do
      {:ok, _} ->
        round = Rounds.get_round!(round_id)

        case round.pairings
             |> Enum.all?(fn p -> p.active == false end) do
          true -> Rounds.update_round(round, %{active: false})
          false -> nil
        end

        {:noreply,
         socket
         |> put_flash(:info, "Pod updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Error updating pairing")}
    end
  end
end
