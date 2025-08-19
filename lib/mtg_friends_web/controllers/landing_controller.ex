defmodule MtgFriendsWeb.LandingController do
  use MtgFriendsWeb, :controller

  alias MtgFriends.Tournaments

  def index(conn, _params) do
    latest_tournaments = Tournaments.get_most_recent_tournaments(4)

    supporters = [
      %{
        name: "Istmo Games Panamá",
        image: "supporters/istmo-games.webp",
        url: "https://www.instagram.com/istmogames/"
      },
      %{
        name: "Card Merchant NZ",
        image: "supporters/card-merchant.webp",
        url: "https://cardmerchant.co.nz/"
      },
      %{
        name: "Dank Confidants",
        image: "supporters/dank-confidants.webp",
        url: "https://www.instagram.com/dankconfidants/"
      },
      %{
        name: "War Room",
        image: "supporters/war-room-black.webp",
        url: "https://www.instagram.com/warroompanama/"
      },
      %{
        name: "TCG Pokémon Chitré",
        image: "supporters/pokemon-chitre.webp",
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
