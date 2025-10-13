defmodule ExolyteWeb.SessionController do
  use ExolyteWeb, :controller

  plug :put_layout, html: {ExolyteWeb.Layouts, :root}

  def new(conn, _params) do
    render(conn, :login)
  end

  def create(conn, %{"user_id" => user_id, "password" => password}) do
    case Exolyte.UserDB.authenticate(user_id, password) do
      {:ok, user_id} ->
        conn
        |> put_session(:user_id, user_id)
        |> redirect(to: "/mypage")

      {:error, _reason} ->
        conn
        |> put_flash(:error, gettext("Login failed."))
        |> render(:login)
    end
  end
end
