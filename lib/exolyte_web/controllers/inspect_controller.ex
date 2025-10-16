defmodule ExolyteWeb.InspectController do
  use ExolyteWeb, :controller

  def show(conn, _params) do
    conn
    |> send_resp(204, "")
  end
end