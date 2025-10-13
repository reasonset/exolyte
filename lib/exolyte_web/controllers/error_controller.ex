defmodule ExolyteWeb.ErrorController do
  use ExolyteWeb, :controller

  def notfound(conn, _) do
    conn
    |> put_status(:not_found)
    |> put_view(ExolyteWeb.ErrorHTML)
    |> render("404.html")
    |> halt
  end
end
