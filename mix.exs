defmodule Barna.MixProject do
  use Mix.Project

  def project do
    [
      app: :barna,
      description: description(),
      package: package(),
      version: "0.2.1",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      elixirc_paths: elixirc_paths(Mix.env())
    ]
  end

  defp description() do
    "Extends your Ecto schemas with convenience functions so that you can focus on your domain logic instead of plumbing."
  end

  defp package() do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/fartek/barna"}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support", "integration_test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ecto_sql, "~> 3.0"},
      {:postgrex, ">= 0.0.0", only: :test},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end
end
