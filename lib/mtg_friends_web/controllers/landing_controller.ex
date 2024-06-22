defmodule MtgFriendsWeb.LandingController do
  use MtgFriendsWeb, :controller

  alias MtgFriends.Tournaments

  def index(conn, _params) do
    latest_tournaments = Tournaments.get_most_recent_tournaments(4)

    supporters = [
      %{
        name: "Dank Confidants",
        image: "supporters/dank-confidants.png",
        url: "https://www.instagram.com/dankconfidants/"
      },
      # %{
      #   name: "Istmo Games Panamá",
      #   image: "supporters/istmo-games",
      #   url: "https://www.instagram.com/istmogames/"
      # },
      %{
        name: "War Room",
        image: "supporters/war-room-black.jpg",
        url: "https://www.instagram.com/warroompanama/"
      },
      %{
        name: "TCG Pokémon Chitré",
        image: "supporters/pokemon-chitre.png",
        url: "https://www.instagram.com/tcgpokemon_chi3/"
      }
    ]

    render(conn, :index, %{
      layout: false,
      latest_tournaments: latest_tournaments,
      supporters: supporters
    })
  end
end
