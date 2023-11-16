defmodule MtgFriendsWeb.TournamentLive.Show do
  alias MtgFriends.Participants
  use MtgFriendsWeb, :live_view

  alias MtgFriends.Tournaments

  on_mount {MtgFriendsWeb.UserAuth, :mount_current_user}

  @impl true
  def render(assigns) do
    ~H"""
    <.header>
      Tournament: <%= @tournament.name %>
      <:subtitle>This is a tournament record from your database.</:subtitle>
      <:actions>
        <%= if @current_user && @current_user.id == @tournament.user_id do %>
          <.link patch={~p"/tournaments/#{@tournament}/show/edit"} phx-click={JS.push_focus()}>
            <.button>Edit tournament</.button>
          </.link>
        <% end %>
      </:actions>
    </.header>

    <.list>
      <:item title="Name"><%= @tournament.name %></:item>
      <:item title="Location"><%= @tournament.location %></:item>
      <:item title="Date"><%= @tournament.date %></:item>
      <:item title="Active"><%= @tournament.active %></:item>
      <:item title="Description">
        <%= if @tournament.description_html do %>
          <%= raw(@tournament.description_html) %>
        <% end %>
      </:item>
      <%!-- <:item title="Standings">
        <%= if @tournament.standings_raw do %>
          <%= raw(String.replace(@tournament.standings_raw, "\n", "<br/>")) %>
        <% end %>
      </:item> --%>
    </.list>

    <.simple_form for={@form} id="participant_count" phx-submit="add_participants">
      <.input field={@form[:participant_count]} type="number" />
      <:actions>
        <.button phx-disable-with="Confirming..." class="w-full">Add participants</.button>
      </:actions>
    </.simple_form>

    <.table id="tournaments" rows={@tournament.participants}>
      <:col :let={participant} label="Name">
        <%= inspect(participant) %>
        <p><%= participant.name %></p>
      </:col>
      <:col :let={participant} label="Points">
        <p><%= participant.points %></p>
      </:col>
      <:col :let={participant} label="Decklist">
        <p><%= participant.decklist %></p>
      </:col>
    </.table>

    <.back navigate={~p"/tournaments"}>Back to tournaments</.back>

    <.modal
      :if={@live_action == :edit}
      id="tournament-modal"
      show
      on_cancel={JS.patch(~p"/tournaments/#{@tournament}")}
    >
      <.live_component
        module={MtgFriendsWeb.TournamentLive.TournamentEditFormComponent}
        current_user={@current_user}
        id={@tournament.id}
        title={@page_title}
        action={@live_action}
        tournament={@tournament}
        patch={~p"/tournaments/#{@tournament}"}
      />
    </.modal>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket |> assign(:form, to_form(%{"participant_count" => 4}))}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    tournament = Tournaments.get_tournament!(id)

    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:tournament, tournament)}
  end

  defp page_title(:show), do: "Show Tournament"
  defp page_title(:edit), do: "Edit Tournament"

  def handle_event("add_participants", %{"participant_count" => participants_str}, socket) do
    tournament_id = socket.assigns.tournament.id
    {participant_count, ""} = Integer.parse(participants_str)

    case Participants.create_participants(tournament_id, participant_count) do
      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, put_flash(socket, :error, "Something wrong happened")}

      {:ok, participants} ->
        notify_parent({:saved, participants})

        {:noreply,
         socket
         |> put_flash(:info, "Added #{participants_str} participants successfully")
         |> push_navigate(to: ~p"/tournaments/#{tournament_id}")}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
