defmodule MtgFriendsWeb.TournamentLive.Show do
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

    <.back navigate={~p"/tournaments"}>Back to tournaments</.back>

    <.modal
      :if={@live_action == :edit}
      id="tournament-modal"
      show
      on_cancel={JS.patch(~p"/tournaments/#{@tournament}")}
    >
      <.live_component
        module={MtgFriendsWeb.TournamentLive.FormComponent}
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
    {:ok, socket}
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
end
