defmodule ExolyteWeb.PageController do
  use ExolyteWeb, :controller

  def home(conn, _params) do
    conn
    |> redirect(to: "/mypage")
  end
end
