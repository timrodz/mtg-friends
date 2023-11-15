defmodule MtgFriendsWeb.TournamentLive.Index do
  use MtgFriendsWeb, :live_view

  alias MtgFriends.Tournaments
  alias MtgFriends.Tournaments.Tournament

  on_mount {MtgFriendsWeb.UserAuth, :mount_current_user}

  def render(assigns) do
    ~H"""
    <.header class="mb-2">
      Listing Tournaments
      <:actions>
        <%= if @current_user do %>
          <.link patch={~p"/tournaments/new"}>
            <.button>New Tournament</.button>
          </.link>
        <% end %>
      </:actions>
    </.header>

    <div id="controls">
      <p class="font-bold">Filter tournaments</p>
      <div class="mt-2">
        <button phx-click="filter-none">all</button>
        <button phx-click="filter-inactive">inactive</button>
        <button phx-click="filter-active">active</button>
      </div>
    </div>

    <.table
      id="tournaments"
      rows={@streams.tournaments}
      row_click={fn {_id, tournament} -> JS.navigate(~p"/tournaments/#{tournament}") end}
    >
      <:col :let={{_id, tournament}} label="Name"><%= tournament.name %></:col>
      <:col :let={{_id, tournament}} label="Location"><%= tournament.location %></:col>
      <:col :let={{_id, tournament}} label="Date"><%= tournament.date %></:col>
      <:col :let={{_id, tournament}} label="Active"><%= tournament.active %></:col>
      <:action :let={{_id, tournament}}>
        <%= if @current_user && @current_user.id == tournament.user_id do %>
          <div class="sr-only">
            <.link navigate={~p"/tournaments/#{tournament}"}>Show</.link>
          </div>
          <.link patch={~p"/tournaments/#{tournament}/edit"}>Edit</.link>
        <% end %>
      </:action>
      <:action :let={{id, tournament}}>
        <%= if @current_user && @current_user.id == tournament.user_id do %>
          <.link
            phx-click={JS.push("delete", value: %{id: tournament.id}) |> hide("##{id}")}
            data-confirm="Are you sure?"
          >
            Delete
          </.link>
        <% end %>
      </:action>
    </.table>

    <.modal
      :if={@live_action in [:new, :edit]}
      id="tournament-modal"
      show
      on_cancel={JS.patch(~p"/tournaments")}
    >
      <.live_component
        module={MtgFriendsWeb.TournamentLive.FormComponent}
        current_user={@current_user}
        id={@tournament.id || :new}
        title={@page_title}
        action={@live_action}
        tournament={@tournament}
        patch={~p"/tournaments"}
      />
    </.modal>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    form_fields = %{"filter_by" => ""}

    {:ok,
     socket
     |> stream(:tournaments, Tournaments.list_tournaments())
     |> assign(form: to_form(form_fields))}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Tournament")
    |> assign(:tournament, Tournaments.get_tournament!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Tournament")
    |> assign(:tournament, %Tournament{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "All Tournaments")
    |> assign(:tournament, nil)
  end

  @impl true
  def handle_info({MtgFriendsWeb.TournamentLive.FormComponent, {:saved, tournament}}, socket) do
    {:noreply, stream_insert(socket, :tournaments, tournament)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    tournament = Tournaments.get_tournament!(id)
    {:ok, _} = Tournaments.delete_tournament(tournament)

    {:noreply, stream_delete(socket, :tournaments, tournament)}
  end

  def handle_event("validate", %{"filter_by" => form}, socket) do
    IO.inspect(form, label: "form")
    {:noreply, assign(socket, form: to_form(form))}
  end

  @impl true
  def handle_event(event, _, socket) do
    case event do
      "filter-inactive" ->
        {:noreply,
         stream(socket, :tournaments, Tournaments.list_tournaments("filter-inactive"),
           reset: true
         )}

      "filter-active" ->
        {:noreply,
         stream(socket, :tournaments, Tournaments.list_tournaments("filter-active"), reset: true)}

      "filter-none" ->
        {:noreply, stream(socket, :tournaments, Tournaments.list_tournaments(), reset: true)}
    end
  end
end
