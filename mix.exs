defmodule ValidatedStruct.MixProject do
  use Mix.Project

  def project do
    [
      app: :validated_struct,
      version: "0.1.0",
      elixir: "~> 1.16",
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps()
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
      {:stream_data, "~> 1.0", only: [:dev, :test]},
      {:typed_struct, "~> 0.3.0"},
      {:type_resolver, "~> 0.1.7"},
      {:validixir, "~> 1.2.4"}
    ]
  end
end
