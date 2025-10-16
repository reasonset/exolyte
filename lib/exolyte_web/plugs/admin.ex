defmodule ExolyteWeb.Plugs.Admin do
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    admin_token = Application.get_env(:exolyte, :admin)[:token]
    recv_token = List.first(get_req_header(conn, "x-admin-token"))
    if admin_token == recv_token do
      conn
      |> assign(:permit_mode, "admin")
    else
      conn
      |> send_resp(403, "")
      |> halt
    end
  end
end