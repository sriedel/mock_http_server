defmodule MockHttpServer.Mixfile do
  use Mix.Project

  def project do
    [app: :mock_http_server,
     version: "0.2.5",
     elixir: "~> 1.7",
     build_embedded:  Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps(),
     description: "A mock http server for testing/mocking remote http calls",
     package: [ licenses: [ "LGPL 2" ],
                links: %{ "GitHub" => "https://github.com/sriedel/mock_http_server" } ],
     source_url: "https://github.com/sriedel/mock_http_server"
   ]
  end

  # Configuration for the OTP application
  #
  # Type `mix help compile.app` for more information
  def application do
    [ 
      extra_applications: [:logger, :cowboy, :plug],
      mod: { MockHttpServer, [] }
    ]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type `mix help deps` for more examples and options
  defp deps do
    [ { :plug, "~> 1.7.0" },
      { :cowboy, "~> 2.6.0" },
      { :plug_cowboy, "~> 2.0.0" },
      { :logger_file_backend, "0.0.10", only: :test },
      { :ex_doc, ">= 0.0.0", only: :dev }
    ]
  end
end
