defmodule ExolyteWeb.AdminController do
  use ExolyteWeb, :controller

  def join(conn, params) do
    with %{"user_id" => user_id, "channel_id" => channel_id} <- params do
      case Exolyte.UserDB.get_user(user_id) do
        nil ->
          conn
          |> send_resp(404, "")
          |> halt

        _user ->
          case Exolyte.ChannelDB.add_user(channel_id, user_id) do
            {:ok, ch} ->
              conn
              |> send_resp(200, inspect(ch))

            {:error, _} ->
              conn
              |> send_resp(404, "")
              |> halt
          end
      end
    else
      _ ->
        conn
        |> send_resp(400, "")
        |> halt
    end
  end

  def create_channel(conn, params) do
    with %{"channel_id" => channel_id, "name" => name} <- params do
      case Exolyte.ChannelDB.create_channel(channel_id, name) do
        :ok ->
          conn
          |> send_resp(204, "")
          |> halt

        _ ->
          conn
          |> send_resp(500, "")
          |> halt
      end
    else
      _ ->
        conn
        |> send_resp(400, "")
        |> halt
    end
  end

  def create_user(conn, params) do
    with %{"user_id" => user_id, "display_name" => display_name, "password" => password} <- params do
      user = Exolyte.UserDB.put_user(user_id, display_name, password)

      conn
      |> send_resp(200, JSON.encode!(user))
      |> halt
    else
      _ ->
        conn
        |> send_resp(400, "")
        |> halt
    end
  end

  def reset_user(conn, params) do
    with %{"user_id" => user_id} <- params do
      link = Exolyte.UserDB.create_reset_link(user_id)

      conn
      |> send_resp(200, JSON.encode!(%{"link_uuid" => link}))
      |> halt
    else
      _ ->
        conn
        |> send_resp(400, "")
        |> halt
    end
  end

end