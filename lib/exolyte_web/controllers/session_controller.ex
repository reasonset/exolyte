defmodule ExolyteWeb.SessionController do
  use ExolyteWeb, :controller

  plug :put_layout, html: {ExolyteWeb.Layouts, :root}

  def new(conn, _params) do
    render(conn, :login)
  end

  def create(conn, %{"userid" => userid, "password" => password}) do
    case Exolyte.UserDB.authenticate(userid, password) do
      {:ok, user_id} ->
        conn
        |> put_session(:user_id, user_id)
        |> redirect(to: "/")

      {:error, _reason} ->
        conn
        |> put_flash(:error, gettext("Login failed."))
        |> render(:login)
    end
  end
end
