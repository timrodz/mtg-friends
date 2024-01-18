defmodule MtgFriendsWeb.TournamentLive.RoundEditFormComponent do
  use MtgFriendsWeb, :live_component

  alias MtgFriends.Pairings
  alias MtgFriends.Participants
  alias MtgFriends.Tournaments
  alias MtgFriends.Rounds

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
          <.button phx-disable-with="Saving...">Submit changes</.button>
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

    {:ok, updated_pairing_tuples} = Pairings.update_pairings(tournament_id, round_id, params)

    tournament = Tournaments.get_tournament_simple!(tournament_id)
    round = Rounds.get_round!(round_id, true)

    # If all round pairings have finished, finish the round automatically
    all_pairings_done? = Enum.all?(round.pairings, fn p -> p.active == false end)

    case all_pairings_done? do
      true ->
        Rounds.update_round(round, %{active: false})
        # Last round of the tournament - finish it
        case tournament.round_count == round.number + 1 do
          true ->
            updated_pairings = updated_pairing_tuples |> Enum.map(fn {id, pairing} -> pairing end)
            process_last_tournament_round(socket, tournament, updated_pairings)

          false ->
            {:noreply,
             socket
             |> put_flash(:info, "Pod updated successfully")
             |> push_patch(to: socket.assigns.patch)}
        end

      false ->
        {:noreply,
         socket
         |> put_flash(:info, "Pod updated successfully")
         |> push_patch(to: socket.assigns.patch)}
    end
  end

  def process_last_tournament_round(socket, tournament, pairings) do
    # Assign the tournament's winner if it's top cut 4, as that round's winner may have less points than another player
    with true <- tournament.is_top_cut_4,
         winning_pairing <- Enum.find(pairings, fn p -> p.winner end),
         false <- is_nil(winning_pairing) do
      {:ok, _} =
        Participants.update_participant(winning_pairing.participant, %{
          "is_tournament_winner" => true
        })
    end

    {:ok, _} = Tournaments.update_tournament(tournament, %{"status" => :finished})

    {:noreply,
     socket
     |> put_flash(:info, "Last pod updated successfully - Tournament has finished!")
     |> push_navigate(to: ~p"/tournaments/#{tournament.id}")}
  end
end
