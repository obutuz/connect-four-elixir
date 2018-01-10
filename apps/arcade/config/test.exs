use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :arcade, ArcadeWeb.Endpoint,
  http: [port: System.get_env("PORT") || 4001],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn
