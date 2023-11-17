defmodule MtgFriendsWeb.TournamentLive.Round do
  use MtgFriendsWeb, :live_view

  alias MtgFriendsWeb.Live.TournamentLive.Utils
  alias MtgFriends.Participants
  alias MtgFriends.Pairings
  alias MtgFriends.Tournaments
  alias MtgFriends.Rounds

  on_mount {MtgFriendsWeb.UserAuth, :mount_current_user}

  def render(assigns) do
    ~H"""
    <.header>
      Tournament: <%= @tournament_name %>
      <:subtitle>
        Round #<%= @round_number + 1 %> — Status: <%= (@round_active && "In progress 🟢") ||
          "Finished 🔴" %>
      </:subtitle>
    </.header>
    <.warning :if={not @round_active && @is_current_user_tournament_owner} class="text-xs">
      TEST period notice: As the owner of this tournament, you can still edit pod results
    </.warning>

    <.back navigate={~p"/tournaments/#{@tournament_id}"}>Back to tournament</.back>

    <div id="pairings" class="mt-8">
      <h2>Pods for round #<%= @round_number + 1 %></h2>
      <div class="mt-4 grid grid-cols-1 md:grid-cols-2 gap-2">
        <div
          :for={{pairing_number, pairing_group} <- @pairing_groups}
          id={"tournament-#{@tournament_id}-round-#{@round_id}-pairing-number-#{pairing_number}"}
          class={["border rounded-lg p-4"]}
        >
          <p class="font-semibold">
            Pod #<%= pairing_number %> — <%= (pairing_group.active && "In progress 🟢") ||
              "Finished 🔴" %>
          </p>
          <div class="grid grid-cols-1 gap-2 p-3 mb-2">
            <div
              :for={pairing <- pairing_group.pairings}
              id={"tournament-#{@tournament_id}-round-#{@round_id}-pairing-number-#{pairing_number}-#{pairing.id}"}
              class={[
                "flex justify-between items-center gap-2 py-1 px-2 rounded-md",
                (pairing.winner && "font-bold bg-green-200") || ""
              ]}
            >
              <p class="flex gap-1 items-center">
                <%= pairing.participant.name %>
                <.icon :if={pairing.winner} name="hero-trophy" class="h-5 w-5" />
              </p>
              <p>
                Points: <%= pairing.points %>
              </p>
            </div>
          </div>
          <.link
            :if={@is_current_user_tournament_owner}
            patch={
              ~p"/tournaments/#{@tournament_id}/rounds/#{@round_number + 1}/edit_pairing/#{pairing_number + 1}"
            }
            phx-click={JS.push_focus()}
          >
            <.button_secondary>
              <%= (pairing_group.active && "Add") ||
                "Update" %> pod results
            </.button_secondary>
          </.link>
        </div>
      </div>

      <.modal
        :if={@live_action == :edit}
        id={"pairing-modal-#{@selected_page_number}"}
        show
        on_cancel={JS.patch(~p"/tournaments/#{@tournament_id}/rounds/#{@round_number + 1}")}
      >
        <.live_component
          module={MtgFriendsWeb.TournamentLive.RoundEditFormComponent}
          current_user={@current_user}
          id={@selected_page_number}
          title={@page_title}
          action={@live_action}
          tournament_id={@tournament_id}
          round_id={@round_id}
          form={Enum.at(@forms, @selected_page_number - 1) |> elem(1)}
          patch={~p"/tournaments/#{@tournament_id}/rounds/#{@round_number + 1}"}
        />
      </.modal>

      <div class="mt-4">
        <%= if not(@has_pairings) do %>
          <.button :if={@is_current_user_tournament_owner} phx-click="create-pods">
            Create pods
          </.button>
        <% else %>
          <.button :if={@round_active} phx-click="finish-round">Finish round</.button>
        <% end %>
      </div>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp generate_socket(socket, tournament_id, round_number) do
    round = Rounds.get_round!(tournament_id, round_number)

    pairing_groups =
      Enum.group_by(round.pairings, fn pairing -> pairing.number end)
      |> Enum.map(fn {index, pairings} ->
        {index,
         %{
           pairings: pairings,
           active: Enum.any?(pairings, fn p -> p.active == true end),
           pairing_winner: Enum.find(pairings, fn p -> p.winner end)
         }}
      end)

    forms =
      pairing_groups
      |> Enum.map(fn {index, pairing_groups} ->
        {index,
         to_form(%{
           "pairing_number" => index,
           "winner_id" => "",
           "participants" =>
             Enum.map(pairing_groups.pairings, fn pairing ->
               %{
                 id: pairing.participant.id,
                 points: pairing.points || 0,
                 name: pairing.participant.name
               }
             end)
         })}
      end)

    socket
    |> assign(
      round_id: round.id,
      round_number: round.number,
      round_active: round.active,
      has_pairings: length(round.pairings) > 0
    )
    |> assign(
      tournament_id: round.tournament.id,
      tournament_name: round.tournament.name,
      participants: round.tournament.participants
    )
    |> assign(pairing_groups: pairing_groups, forms: forms)
    |> Utils.assign_current_user_tournament_owner(
      socket.assigns.current_user,
      round.tournament
    )
  end

  defp apply_action(socket, :index, %{
         "tournament_id" => tournament_id,
         "round_number" => round_number
       }) do
    socket
    |> assign(:page_title, "Round Pairings")
    |> assign(:selected_page_number, nil)
    |> generate_socket(tournament_id, round_number)
  end

  defp apply_action(socket, :edit, %{
         "tournament_id" => tournament_id,
         "round_number" => round_number,
         "pairing_number" => pairing_number_str
       }) do
    {pairing_number, ""} = Integer.parse(pairing_number_str)

    socket
    |> assign(:page_title, "Update pod results")
    |> assign(:selected_page_number, pairing_number)
    |> generate_socket(tournament_id, round_number)
  end

  @impl true
  def handle_event("finish-round", _, socket) do
    %{round_number: round_number, round_id: round_id} = socket.assigns

    round = Rounds.get_round!(round_id)

    case Rounds.update_round(round, %{active: false}) do
      {:ok, round} ->
        {:noreply,
         socket
         |> put_flash(:info, "Round #{round_number + 1} finished successfully")
         |> reload_page()}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply,
         put_flash(socket, :error, "Something wrong happened when finishing this round")}
    end
  end

  @impl true
  def handle_event("create-pods", _, socket) do
    %{tournament_id: tournament_id, round_id: round_id, participants: participants} =
      socket.assigns

    # TODO: Order from highest points to lowest points
    participant_pairings = Enum.chunk_every(participants, 4)

    participant_pairings
    |> Enum.with_index(fn pairing, index ->
      for participant <- pairing do
        Pairings.create_pairing(%{
          number: index,
          tournament_id: tournament_id,
          round_id: round_id,
          participant_id: participant.id
        })
      end
    end)

    {:noreply, socket |> put_flash(:info, "Pairings created successfully") |> reload_page()}
  end

  defp reload_page(socket) do
    socket
    |> push_navigate(
      to:
        ~p"/tournaments/#{socket.assigns.tournament_id}/rounds/#{socket.assigns.round_number + 1}"
    )
  end
end
