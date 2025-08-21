defmodule MtgFriendsWeb.Layouts do
  use MtgFriendsWeb, :html

  embed_templates "layouts/*"

  @spec app(any()) :: Phoenix.LiveView.Rendered.t()
  def app(assigns) do
    ~H"""
    <div class="navbar bg-base-100 border-base-300 border-b-[1px] px-4 lg:px-10">
      <div class="navbar-start">
        <.link
          navigate={
            case is_nil(@current_user) do
              true -> ~p"/"
              false -> ~p"/tournaments"
            end
          }
          target={if is_nil(@current_user), do: "_blank", else: ""}
        >
          <span class="text-lg md:text-2xl text-primary font-bold">
            ⚔ Tie Breaker
          </span>
        </.link>
      </div>
      <div class="navbar-end">
        <div class="dropdown dropdown-left">
          <div tabindex="0" role="button" class="btn btn-ghost btn-circle">
            <.icon name="hero-bars-3-solid" />
          </div>
          <ul
            tabindex="0"
            class="menu menu-sm dropdown-content bg-base-100 rounded-box z-1 card card-border space-y-1"
          >
            <li>
              <.link navigate={~p"/"}>
                <.icon name="hero-home-solid" /> Home
              </.link>
            </li>
            <li>
              <.link navigate={~p"/tournaments"}>
                <.icon name="hero-rocket-launch-solid" /> Tournaments
              </.link>
            </li>
            <%= if @current_user do %>
              <li>
                <.link navigate={~p"/users/settings"}>
                  <.icon name="hero-cog-6-tooth-solid" /> Settings
                </.link>
              </li>
              <li>
                <.link
                  href={~p"/users/log_out"}
                  method="delete"
                >
                  <.icon name="hero-arrow-right-start-on-rectangle-solid" /> Log out
                </.link>
              </li>
            <% else %>
              <li>
                <.link navigate={~p"/users/register"}>
                  Register
                </.link>
              </li>
              <li>
                <.link navigate={~p"/users/log_in"}>
                  Log in
                </.link>
              </li>
            <% end %>
          </ul>
        </div>
      </div>
    </div>
    <main class="px-4 py-20 sm:px-6 lg:px-8">
      <div class="mx-auto max-w-2xl space-y-4">
        {@inner_content}
      </div>
    </main>

    <footer class="footer sm:footer-horizontal footer-center bg-base-100 border-base-300 border-t-[1px] text-base-content p-4 bottom-0">
      <aside>
        <p>
          Copyright © {DateTime.utc_now().year} —
          <.link navigate="https://timrodz.dev" target="_blank" class="link link-hover">
            Juan Morais
          </.link>
        </p>
        <.theme_toggle />
      </aside>
    </footer>

    <.flash_group flash={@flash} />
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
