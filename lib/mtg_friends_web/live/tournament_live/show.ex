defmodule MtgFriendsWeb.TournamentLive.Show do
  use MtgFriendsWeb, :live_view

  alias MtgFriends.Tournaments

  on_mount {MtgFriendsWeb.UserAuth, :mount_current_user}

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:tournament, Tournaments.get_tournament!(id))}
  end

  defp page_title(:show), do: "Show Tournament"
  defp page_title(:edit), do: "Edit Tournament"

  def render_description(description) do
    cards_to_search =
      Regex.scan(~r/\[\[.*\]\]/, description)
      |> Enum.map(&hd/1)

    # for card <- cards_to_search do
    #   a = https://api.scryfall.com/cards/named?fuzzy=#
    # end

    String.replace(
      String.replace(description, "\n", "</br>"),
      cards_to_search,
      fn x ->
        x
        |> String.replace("[[", "")
        |> String.replace("]]", "")
        |> then(
          &"<a class=\"underline\" target=\"_blank\" href=\"https://api.scryfall.com/cards/named?fuzzy=#{String.replace(&1, " ", "+")}\">#{&1}</a>"
        )
      end
    )
  end
end
