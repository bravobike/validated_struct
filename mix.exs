defmodule ValidatedStruct.MixProject do
  use Mix.Project

  @version "0.0.1"
  @github_page "https://github.com/bravobike/validated_struct"

  def project do
    [
      app: :validated_struct,
      version: "0.0.1",
      elixir: "~> 1.16",
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps(),

      # doc
      name: "ValidatedStruct",
      description: "A library to define validated structs",
      homepage_url: @github_page,
      source_url: @github_page,
      docs: docs(),
      package: package()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "dev", "test/support"]
  defp elixirc_paths(:dev), do: ["lib", "dev"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:typed_struct, "~> 0.3.0"},
      {:type_resolver, "~> 0.1.7"},
      {:validixir, "~> 1.2.4"}
    ]
  end

  defp docs() do
    [
      api_reference: false,
      authors: ["Simon Härer, Norbert Melzer"],
      canonical: "http://hexdocs.pm/validated_struct",
      main: "ValidatedStruct",
      source_ref: "v#{@version}"
    ]
  end

  defp package do
    [
      files: ~w(mix.exs README.md lib .formatter.exs),
      licenses: ["Apache-2.0"],
      links: %{
        "GitHub" => @github_page
      },
      maintainers: ["Simon Härer, Norbert Melzer"]
    ]
  end
end
