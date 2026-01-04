defmodule MtgFriendsWeb.Router do
  use MtgFriendsWeb, :router
  alias OpenApiSpex

  import MtgFriendsWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {MtgFriendsWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
  end

  pipeline :api do
    plug :accepts, ["json"]
    plug OpenApiSpex.Plug.PutApiSpec, module: MtgFriendsWeb.ApiSpec
    plug :rate_limit
  end

  pipeline :api_authenticated do
    plug MtgFriendsWeb.APIAuthPlug
  end

  pipeline :authorize_tournament_owner do
    plug MtgFriendsWeb.Plugs.AuthorizeTournamentOwner
  end

  scope "/", MtgFriendsWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :require_authenticated_user,
      on_mount: [{MtgFriendsWeb.UserAuth, :ensure_authenticated}] do
      live "/users/settings", UserSettingsLive, :edit
      live "/users/settings/confirm_email/:token", UserSettingsLive, :confirm_email

      live "/tournaments/:id/show/edit", TournamentLive.Show, :edit
      live "/tournaments/:id/show/end", TournamentLive.Show, :end
      live "/tournaments/new", TournamentLive.Index, :new
      live "/tournaments/:id/edit", TournamentLive.Index, :edit

      live "/tournaments/:tournament_id/rounds/:round_number/pairing/:pairing_id/edit",
           TournamentLive.Round,
           :edit
    end
  end

  scope "/", MtgFriendsWeb do
    pipe_through :browser

    get "/", LandingController, :index
    live "/tournaments", TournamentLive.Index, :index
    live "/tournaments/:id", TournamentLive.Show, :show
    live "/tournaments/:tournament_id/rounds/:round_number", TournamentLive.Round, :index
  end

  scope "/api", MtgFriendsWeb do
    pipe_through :api

    post "/login", API.SessionController, :create

    resources "/tournaments", API.TournamentController, only: [:index, :show] do
      resources "/participants", API.ParticipantController, only: [:index, :show]

      resources "/rounds", API.RoundController, only: [:index, :show] do
        resources "/pairings", API.PairingController, only: [:index, :show]
      end
    end
  end

  scope "/api" do
    pipe_through :api
    get "/openapi", OpenApiSpex.Plug.RenderSpec, [MtgFriendsWeb.Schemas]
    get "/swagger", OpenApiSpex.Plug.SwaggerUI, path: "api/openapi", title: "Tie Breaker API"
  end

  scope "/api", MtgFriendsWeb do
    pipe_through [:api, :api_authenticated]

    scope "/tournaments", API do
      post "/", TournamentController, :create

      scope "/:tournament_id" do
        pipe_through :authorize_tournament_owner

        put "/", TournamentController, :update
        delete "/", TournamentController, :delete

        resources "/participants", ParticipantController, only: [:create, :update, :delete]

        resources "/rounds", RoundController, only: [:create, :update, :delete] do
          resources "/pairings", PairingController, only: [:create, :update, :delete]
        end
      end
    end
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:mtg_friends, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: MtgFriendsWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Authentication routes

  scope "/", MtgFriendsWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    live_session :redirect_if_user_is_authenticated,
      on_mount: [{MtgFriendsWeb.UserAuth, :redirect_if_user_is_authenticated}] do
      live "/users/register", UserRegistrationLive, :new
      live "/users/log_in", UserLoginLive, :new
      live "/users/reset_password", UserForgotPasswordLive, :new
      live "/users/reset_password/:token", UserResetPasswordLive, :edit
    end

    post "/users/log_in", UserSessionController, :create
  end

  scope "/", MtgFriendsWeb do
    pipe_through [:browser]

    delete "/users/log_out", UserSessionController, :delete

    live_session :current_user,
      on_mount: [{MtgFriendsWeb.UserAuth, :mount_current_user}] do
      live "/users/confirm/:token", UserConfirmationLive, :edit
      live "/users/confirm", UserConfirmationInstructionsLive, :new
    end
  end

  scope "/admin", MtgFriendsWeb do
    pipe_through [:browser, :require_admin_user]

    live_session :admin_current_user,
      on_mount: [{MtgFriendsWeb.UserAuth, :mount_current_user}] do
      live "/", AdminLive.Index

      live "/games", GameLive.Index, :index
      live "/games/new", GameLive.Index, :new
      live "/games/:id/edit", GameLive.Index, :edit

      live "/games/:id", GameLive.Show, :show
      live "/games/:id/show/edit", GameLive.Show, :edit
    end
  end

  defp rate_limit(conn, _opts) do
    if Application.get_env(:mtg_friends, :disable_rate_limit) do
      conn
    else
      # Get IP based on RemoteIP or just remote_ip if not using a proxy middleware yet
      # Since we don't have RemoteIP plug configured in Endpoint (observed in application files), we use conn.remote_ip directly.
      # Note: If behind a proxy (Fly.io, etc), real IP header parsing is needed.
      # Assuming standard conn.remote_ip is correct for now or handled by Endpoint configuration.

      case MtgFriendsWeb.RateLimit.hit("api:#{inspect(conn.remote_ip)}", 60_000, 60) do
        {:allow, _count} ->
          conn

        {:deny, _limit} ->
          conn
          |> put_status(:too_many_requests)
          |> put_resp_content_type("application/json")
          |> send_resp(429, Jason.encode!(%{error: "Rate limit exceeded"}))
          |> halt()
      end
    end
  end
end
