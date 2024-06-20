defmodule MtgFriendsWeb.PageController do
  use MtgFriendsWeb, :controller

  alias MtgFriends.Tournaments

  def index(conn, _params) do
    latest_tournaments = Tournaments.get_most_recent_tournaments(6)

    supporters = [
      %{
        name: "Dank Confidants",
        image: "/supporters/dank-confidants.png",
        url: "https://www.twitch.tv/dankconfidants"
      },
      %{
        name: "TCG Pokémon Chitré",
        image: "/supporters/pokemon-chitre.jpeg",
        url: ""
      },
      %{
        name: "Istmo Games Panamá",
        image: "/supporters/",
        url: ""
      }
    ]

    render(conn, :index, %{
      layout: false,
      latest_tournaments: latest_tournaments,
      supporters: supporters
    })
  end
end
