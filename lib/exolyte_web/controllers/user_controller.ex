defmodule ExolyteWeb.UserController do
  use ExolyteWeb, :controller

  plug :put_layout, html: {ExolyteWeb.Layouts, :root}

  def show(conn, %{"link_uuid" => link_uuid}) do
    case Exolyte.UserDB.get_reset_link(link_uuid) do
      {:ok, user_id} ->
        conn
        |> assign(:user_id, user_id)
        |> assign(:link_uuid, link_uuid)
        |> render(:reset)

      _ ->
        conn
        |> send_resp(404, [])
        |> halt
    end
  end

  def reset(conn, %{"link_uuid" => link_uuid, "password" => password}) do
    case Exolyte.UserDB.get_reset_link(link_uuid) do
      {:ok, user_id} ->
        Exolyte.UserDB.password_reset(user_id, password)

        conn
        |> put_session(:user_id, user_id)
        |> redirect(to: "/mypage")

      _ ->
        conn
        |> send_resp(404, "")
        |> halt
    end
  end
end
