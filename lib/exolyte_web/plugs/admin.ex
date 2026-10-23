defmodule ExolyteWeb.Plugs.Admin do
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    admin_token = Application.get_env(:exolyte, :admin)[:token]
    recv_token = List.first(get_req_header(conn, "x-admin-token"))

    valid? =
      is_binary(admin_token) and admin_token != "" and
        is_binary(recv_token) and
        Plug.Crypto.secure_compare(admin_token, recv_token)

    if valid? do
      conn
      |> assign(:permit_mode, "admin")
    else
      conn
      |> send_resp(403, "")
      |> halt
    end
  end
end
