defmodule MtgFriendsWeb.LandingHTML do
  use MtgFriendsWeb, :html

  def index(assigns) do
    ~H"""
    <.flash_group flash={@flash} />
    <main id="landing-page">
      <div class="max-w-screen-md mx-auto">
        <div id="hero" class="pt-12 flex justify-center items-center">
          <h1>
            ⚔ Tie Breaker
          </h1>
        </div>
        <p class="mt-2 text-lg text-center italic">TCG tournaments made easy</p>
        <div id="actions" class="mt-8 flex gap-3 justify-center">
          <.link class="btn btn-primary" patch={~p"/tournaments/new"}>Host a tournament</.link>
          <.link class="btn btn-primary btn-soft" navigate="#about">Learn more</.link>
        </div>
        <section id="tournaments">
          <h2>Latest tournaments</h2>
          <.item_grid
            id="tournaments"
            items={@latest_tournaments}
            item_click={fn tournament -> JS.navigate(~p"/tournaments/#{tournament}") end}
            class="!mt-0"
          >
            <:item :let={t} class="flex flex-col justify-between">
              <h3 class="truncate font-semibold !my-0 !mb-1">{t.name}</h3>
              <div>
                <p class="game-name">{t.game.name}</p>
                <.date dt={t.date} />
                <h4 :if={t.location} class="icon-text">
                  <.icon name="hero-map-pin-solid" /> {t.location}
                </h4>
                <.tournament_status value={t.status} />
              </div>
            </:item>
          </.item_grid>

          <div class="inline-block">
            <.link navigate={~p"/tournaments"} class="icon-text btn btn-info">
              <.icon name="hero-chevron-right" /> See all tournaments
            </.link>
          </div>
        </section>
        <section id="about">
          <h2>What is Tie Breaker?</h2>
          <hr />
          <p>
            This project was born out of love for competitive EDH, a multiplayer format for Magic: The Gathering (MTG). It all started when my friends introduced me to MTG, and I got instantly hooked with the game. We would often organize events and tournaments, but I noticed we had difficulty when hosting tournaments:
            <i>from pairings to score-keeping, I knew what to do</i>
            💡
          </p>
          <p>
            Since this is a side project, I'm always open to new ideas, no matter how wonky they might seem. Contact me via
            <a href="mailto:juan@timrodz.dev" class="p-0">juan@timrodz.dev</a>
            and we'll cook up something together.
          </p>
        </section>
        <section id="supporters">
          <h2>Our supporters</h2>
          <hr />
          <p class="text-lg">Trusted by WPN stores & streamers alike—Tie Breaker meets your needs.</p>
          <div class="mt-6 lg:mt-3 mb-8 supporter-carousel grid grid-cols-2 md:grid-cols-3 gap-10 justify-items-center">
            <%= for s <- @supporters do %>
              <.link
                :if={s.image}
                class="w-32 lg:w-52 flex items-center justify-center p-0 border-0"
                href={s.url}
                target="_blank"
                rel="noopener noreferrer"
              >
                <img src={"/images/#{s.image}"} alt={s.name} class="object-contain rounded-md" />
              </.link>
            <% end %>
          </div>
          <div>
            <blockquote class="px-4 py-2 my-4 border-l-4 border-accent">
              I've been testing different methods of pairing for a long time, and this app is exactly what I've been looking for. It offers an intuitive and streamlined process for organizing matches and tournaments, with an easy and user-friendly interface. Also, it's updated regularly with bug fixes and improvements. Recommended!
            </blockquote>
            <p class="text-base-100">Jorge Ortíz — Data Engineer & MTG Streamer (DankConfidants)</p>
          </div>
        </section>
        <section id="faq">
          <h2 class="mt-8">Frequently Asked Questions</h2>
          <hr />

          <div id="faq-contents" class="mt-3 flex flex-col gap-3">
            <h3>
              What type of events can I run? (Games supported)
            </h3>
            <p>Magic: The Gathering</p>
            <ul>
              <li>Multiplayer / EDH</li>
              <li>1v1 / Standard</li>
            </ul>
            <p>Pokémon</p>
            <ul>
              <li>Standard</li>
            </ul>
            <p>Yu-Gi-Oh!</p>
            <ul>
              <li>Standard</li>
            </ul>
            <h3>
              How do players register for a tournament?
            </h3>
            <p>
              Currently this can only be done by a tournament's host. When creating a tournament, you'll have to say how many participants your tournament allows. However, you can change this number at any time before your tournament begins.
            </p>
            <h3>
              How much does it cost?
            </h3>
            <p>
              TieBreaker is free of use. It was a passion project I started working on, and I don't plan to monetize it at the moment. You're more than welcome to provide feedback and share this app with others!
            </p>
          </div>
        </section>
      </div>
    </main>

    <footer class="footer">
      <div class="max-w-screen-sm mx-auto flex justify-center items-center pt-8 pb-12 px-4 lg:px-0">
        <p class="text-center">
          &copy; 2024 <.link href="https://www.timrodz.dev" target="_blank" class="font-medium">Juan Rodríguez Morais</.link>. Brought to you with the support of many early stage adopters
          <.icon name="hero-heart-solid" />
        </p>
      </div>
    </footer>
    """
  end

  @doc """
  Provides dark vs light theme toggle based on themes defined in app.css.

  See <head> in root.html.heex which applies the theme before page load.
  """
  def theme_toggle(assigns) do
    ~H"""
    <div class="card relative flex flex-row items-center border-2 border-base-300 bg-base-300 rounded-full">
      <div class="absolute w-[33%] h-full rounded-full border-1 border-base-200 bg-base-100 brightness-200 left-0 [[data-theme=light]_&]:left-[33%] [[data-theme=dark]_&]:left-[66%] transition-[left]" />

      <button phx-click={JS.dispatch("phx:set-theme", detail: %{theme: "system"})} class="flex p-2">
        <.icon name="hero-computer-desktop-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button phx-click={JS.dispatch("phx:set-theme", detail: %{theme: "light"})} class="flex p-2">
        <.icon name="hero-sun-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button phx-click={JS.dispatch("phx:set-theme", detail: %{theme: "dark"})} class="flex p-2">
        <.icon name="hero-moon-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>
    </div>
    """
  end
end
