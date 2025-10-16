defmodule ExolyteWeb.Plugs.SetTheme do
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    conn
    |> assign(:user_theme, "kawaiifb")
  end
end