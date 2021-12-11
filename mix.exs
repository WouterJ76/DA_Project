defmodule TwitterClone.MixProject do
  use Mix.Project

  def project do
    [
      app: :twitter_clone,
      version: "0.1.0",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :amqp],
      mod: {TwitterClone, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:jason, "~> 1.2"},
      {:amqp, "~> 3.0"},
      {:uuid, "~> 1.1"}
    ]
  end
end
