defmodule ExolyteWeb.FileController do
  use ExolyteWeb, :controller

  def new(conn, _params) do
    render(conn, :login)
  end

  def bipo(conn, _) do
    conn
    |> send_file(200, "static/bipo.ogg")
  end

  def bipi(conn, _) do
    conn
    |> send_file(200, "static/bipi.ogg")
  end

  def chi(conn, _) do
    conn
    |> send_file(200, "static/chi.ogg")
  end
end
