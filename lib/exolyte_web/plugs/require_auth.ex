defmodule ExolyteWeb.Plugs.RequireAuth do
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    case get_session(conn, :user_id) do
      nil ->
        conn
        |> Phoenix.Controller.redirect(to: "/login")
        |> halt()

      user_id ->
        assign(conn, :current_user, user_id)
    end
  end
end