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
        user = Exolyte.UserDB.get_user(user_id)

        if Map.get(user, :frozen, false) do
          conn
          |> clear_session()
          |> Phoenix.Controller.put_flash(:error, "Account is invalid.")
          |> Phoenix.Controller.redirect(to: "/login")
          |> halt()
        else
          user_theme = if Map.has_key?(user, :theme), do: user.theme, else: "kawaiifb"

          conn
          |> assign(:user_id, user_id)
          |> assign(:current_user, user)
          |> assign(:user_theme, user_theme)
        end

    end
  end
end
