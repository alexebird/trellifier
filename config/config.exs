# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :trellifier,
  #ecto_repos: [Trellifier.Repo],
  from_number: System.get_env("TWILIO_FROM_NUMBER")

# Configures the endpoint
config :trellifier, Trellifier.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "tNQPZR0K+g9IXqVwRlDlhG9FRQTA6v6qyWGOEVpWEwWkCMNJ9A0lsyibSR6URVmq",
  render_errors: [view: Trellifier.ErrorView, accepts: ~w(html json)],
  pubsub: [name: Trellifier.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :ex_twilio,
  account_sid:   System.get_env("TWILIO_ACCOUNT_SID"),
  auth_token:    System.get_env("TWILIO_AUTH_TOKEN")

config :quantum, cron: [
    "0 8 * * *": {"Trellifier", :notify_alex_bird}
  ],
  timezone: "America/Los_Angeles"

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
