defmodule MtgFriendsWeb.TournamentLive.Index do
  use MtgFriendsWeb, :live_view

  alias MtgFriendsWeb.Live.TournamentLive.Utils
  alias MtgFriends.Tournaments
  alias MtgFriends.Tournaments.Tournament

  on_mount {MtgFriendsWeb.UserAuth, :mount_current_user}

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> stream(:tournaments, Tournaments.list_tournaments())}
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
  def handle_info(
        {MtgFriendsWeb.TournamentLive.TournamentEditFormComponent, {:saved, tournament}},
        socket
      ) do
    {:noreply, stream_insert(socket, :tournaments, tournament)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    tournament = Tournaments.get_tournament!(id)
    {:ok, _} = Tournaments.delete_tournament(tournament)

    {:noreply, stream_delete(socket, :tournaments, tournament)}
  end

  def handle_event("validate", %{"filter_by" => form}, socket) do
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
