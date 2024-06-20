defmodule MtgFriendsWeb.PageController do
  use MtgFriendsWeb, :controller

  alias MtgFriends.Tournaments

  def index(conn, _params) do
    latest_tournaments = Tournaments.get_most_recent_tournaments(6)
    render(conn, :index, %{layout: false, latest_tournaments: latest_tournaments})
  end
end
