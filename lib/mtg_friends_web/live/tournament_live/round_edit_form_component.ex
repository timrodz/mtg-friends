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
    %{tournament_id: tournament_id, round_id: round_id, is_top_cut_4?: is_top_cut_4?} =
      socket.assigns

    {:ok, pairings} = Pairings.update_pairings(tournament_id, round_id, params)
    round = Rounds.get_round!(round_id)

    # If all round pairings have finished, finish the round automatically
    all_pairings_done? = round.pairings |> Enum.all?(fn p -> p.active == false end)

    case all_pairings_done? do
      true -> Rounds.update_round(round, %{active: false})
      false -> nil
    end

    # If this round is the top cut 4, finish the tournament as well
    case is_top_cut_4? do
      true ->
        IO.puts("last round")

        with tournament_winner_tuple <-
               Enum.find(pairings, fn pairing_tuple -> elem(pairing_tuple, 1).winner end),
             false <- is_nil(tournament_winner_tuple),
             tournament_winner <-
               elem(tournament_winner_tuple, 1) do
          {:ok, _} =
            Participants.update_participant(tournament_winner.participant, %{"is_winner" => true})
            |> IO.inspect(label: "participant update")

          tournament =
            Tournaments.get_tournament_simple!(tournament_id)

          {:ok, _} =
            Tournaments.update_tournament(tournament, %{"status" => :finished})
            |> IO.inspect(label: "tournament update")

          {:noreply,
           socket
           |> put_flash(:info, "Last pod updated successfully - Tournament has finished!")
           |> push_navigate(to: ~p"/tournaments/#{tournament_id}")}
        else
          _ ->
            {:noreply,
             put_flash(socket, :error, "Error updating pairing")
             |> push_patch(to: socket.assigns.patch)}
        end

      false ->
        {:noreply,
         socket
         |> put_flash(:info, "Pod updated successfully")
         |> push_patch(to: socket.assigns.patch)}
    end
  end
end
