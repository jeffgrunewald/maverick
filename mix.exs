defmodule Goose.MixProject do
  use Mix.Project

  @name "Goose"
  @version "0.1.0"
  @repo "https://github.com/jeffgrunewald/goose"

  def project do
    [
      app: :goose,
      name: @name,
      version: @version,
      elixir: "~> 1.10",
      description: "Web API framework with a need for speed",
      homepage_url: @repo,
      source_url: @repo,
      package: package(),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
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
      {:elli, "~> 3.3"},
      {:jason, "~> 1.2"}
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
      source_ref: "v#{@version}",
      source_url: @repo,
      main: @name
    ]
  end
end
