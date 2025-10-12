defmodule ExolyteWeb.PageController do
  use ExolyteWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
