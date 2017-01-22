use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :trellifier, Trellifier.Endpoint,
  http: [port: 4001],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

# Configure your database
config :trellifier, Trellifier.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "trellifier_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox

config :ex_twilio,
  account_sid:   System.get_env("TWILIO_TEST_ACCOUNT_SID"),
  auth_token:    System.get_env("TWILIO_TEST_AUTH_TOKEN")

config :trellifier,
  from_number: System.get_env("TWILIO_TEST_FROM_NUMBER")
