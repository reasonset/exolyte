defmodule ExolyteWeb.ChannelLogController do
  use ExolyteWeb, :controller

  def show(conn, %{"channel_id" => channel_id, "index" => index}) do
    user_id = conn.assigns.user_id
    log_index = if index == "latest", do: :latest, else: String.to_integer(index)

    case Exolyte.ChannelLog.deliver_log(channel_id, log_index, user_id) do
      {:ok, path} ->
        send_file(conn, 200, path)

      {:error, :channel_not_found} ->
        send_resp(conn, 404, "Channel not found")

      {:error, :log_not_found} ->
        send_resp(conn, 404, "Log not found")

      {:error, :unauthorized} ->
        send_resp(conn, 403, "Forbidden")
    end
  end
end