defmodule SubmarineKata.MixProject do
  use Mix.Project

  def project do
    [
      app: :submarine_kata,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {SubmarineKata.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:phoenix, "~> 1.8.0"},
      {:phoenix_html, "~> 4.1"},
      {:phoenix_live_view, "~> 1.1"},
      {:phoenix_live_dashboard, "~> 0.8"},
      {:gettext, "~> 0.25"},
      {:plug_cowboy, "~> 2.7"},
      {:jason, "~> 1.4"},
      {:tailwind, "~> 0.2.0", runtime: Mix.env() == :dev},
      {:dns_cluster, "~> 0.1.1"},
      {:finch, "~> 0.13"}
    ]
  end
end
