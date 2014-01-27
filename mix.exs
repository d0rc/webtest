defmodule Webtest.Mixfile do
  use Mix.Project

  def project do
    [ app: :webtest,
      version: "0.0.1",
      deps: deps ]
  end

  def application do
    [
      applications: [ :httpoison ]
    ]
  end

  defp deps do
    [
      { :jsex, github: "talentdeficit/jsex" },
      { :cookiejar, github: "d0rc/elixir-cookiejar" },
      { :httpoison, github: "edgurgel/httpoison"}
    ]
  end
end
