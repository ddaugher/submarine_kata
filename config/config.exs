import Config

config :submarine_kata,
  ecto_repos: []

# Configures the endpoint
config :submarine_kata, SubmarineKataWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Phoenix.Endpoint.Cowboy2Adapter,
  render_errors: [
    formats: [html: SubmarineKataWeb.ErrorHTML, json: SubmarineKataWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: SubmarineKata.PubSub,
  live_view: [signing_salt: "0qzCpxqalk9fLySZkcKw5ULYLP4cWTVvKABR6u5KbJl/9ZZLyeiTBzQtymQ8xwht"]

# No esbuild configuration needed - using modern Phoenix approach

# Configure tailwind (the version is required)
config :tailwind,
  version: "3.3.0",
  submarine_kata: [
    args: ~w(
      --config=../tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../assets", __DIR__)
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
