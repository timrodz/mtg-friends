# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :mtg_friends,
  ecto_repos: [MtgFriends.Repo]

# Configures the endpoint
config :mtg_friends, MtgFriendsWeb.Endpoint,
  url: [host: "localhost"],
  render_errors: [
    formats: [html: MtgFriendsWeb.ErrorHTML, json: MtgFriendsWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: MtgFriends.PubSub,
  live_view: [signing_salt: "9D82R4rA"]

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :mtg_friends, MtgFriends.Mailer, adapter: Swoosh.Adapters.Local

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.19.11",
  default: [
    args:
      ~w(js/app.js --bundle --target=es2020 --outdir=../priv/static/assets --external:/fonts/* --external:/images/* --alias:@=.),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => [Path.expand("../deps", __DIR__), Mix.Project.build_path()]}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "4.1.10",
  default: [
    args: ~w(
      --input=assets/css/app.css
      --output=priv/static/assets/app.css
    ),
    cd: Path.expand("..", __DIR__)
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"

config :pre_commit,
  commands: [
    "format",
    "test --cover",
    "dialyzer --format short"
  ],
  verbose: true
