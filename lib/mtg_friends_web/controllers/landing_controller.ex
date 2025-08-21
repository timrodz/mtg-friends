defmodule MtgFriendsWeb.LandingController do
  use MtgFriendsWeb, :controller

  alias MtgFriends.Tournaments

  def index(conn, _params) do
    latest_tournaments = Tournaments.get_most_recent_tournaments(6)

    supporters = [
      %{
        name: "Istmo Games Panamá",
        image: "supporters/istmo-games.webp",
        url: "https://www.instagram.com/istmogames/"
      },
      %{
        name: "Card Merchant Ponsonby",
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

    features = [
      %{
        title: "Host many tournaments",
        description:
          "Register your account (free; email required) and create unlimited tournaments.",
        icon: "hero-rocket-launch-solid"
      },
      %{
        title: "Round management",
        description:
          "Specify the number of rounds and duration for your tournament. Tie Breaker manages the rest. There's even a live timer!",
        icon: "hero-clock-solid"
      },
      %{
        title: "Add participants with ease",
        description:
          "Give us a list of who you want to add, and they'll be added to your tournament. Assign decklists and remove participants too. Coming up next: dropping participants mid-way.",
        icon: "hero-user-plus-solid"
      },
      %{
        title: "Diverse pairing systems",
        description:
          "Generate pairings using bubble sorting or swiss algorithms—whatever suits your needs. When matches finish, simply assign points to players based on the end results. You get to decide how points are awarded.",
        icon: "hero-squares-plus-solid"
      },
      %{
        title: "Open source",
        description:
          "Tie Breaker is powered by the awesome Phoenix framework, and is open for anyone to contribute. Visit our <a href=\"https://github.com/timrodz/mtg-friends\" class=\"link\" target=\"_blank\">Github</a> repository for more information.",
        icon: "hero-code-bracket-solid"
      },
      %{
        title: "Describe specific cards with Scryfall data",
        description:
          "When creating your tournament, use Scryfall notation to describe specific cards. Example: <span class=\"font-mono\">[[Wheel Of Fortune]]</span>",
        icon: "hero-link-solid"
      }
    ]

    render(conn, :index, %{
      page_title: "Home",
      latest_tournaments: latest_tournaments,
      supporters: supporters,
      features: features
    })
  end
end
