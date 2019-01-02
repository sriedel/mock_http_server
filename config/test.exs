use Mix.Config

config :logger,
  backends: [{LoggerFileBackend, :log}]

# configuration for the {LoggerFileBackend, :error_log} backend
config :logger, :log,
  path: "log/test.log",
  level: :debug
