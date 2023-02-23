defmodule Maverick.MixProject do
  use Mix.Project

  @name "Maverick"
  @version "0.3.0"
  @repo "https://github.com/jeffgrunewald/maverick"

  def project do
    [
      app: :maverick,
      name: @name,
      version: @version,
      elixir: "~> 1.12",
      description: "Web API framework with a need for speed",
      homepage_url: @repo,
      source_url: @repo,
      package: package(),
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps(),
      dialyzer: dialyzer(),
      docs: docs()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:plug, "~> 1.14"},
      {:jason, "~> 1.4"},
      {:nimble_parsec, "~> 1.2", optional: true},
      {:dialyxir, "~> 1.2", only: :dev, runtime: false},
      {:finch, "~> 0.14", only: :test},
      {:bandit, "~> 0.6", only: :test},
      {:ex_doc, "~> 0.29", only: :dev, runtime: false}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp dialyzer() do
    [
      plt_add_apps: [:mix],
      plt_file: {:no_warn, ".dialyzer/#{System.version()}.plt"}
    ]
  end

  defp package do
    %{
      licenses: ["Apache 2.0"],
      maintainers: ["Jeff Grunewald"],
      links: %{"GitHub" => @repo}
    }
  end

  defp docs do
    [
      logo: "assets/maverick-logo.png",
      source_ref: "v#{@version}",
      source_url: @repo,
      main: @name
    ]
  end
end
