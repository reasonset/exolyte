defmodule ExolyteWeb.LiveAuth do
  import Phoenix.LiveView
  use ExolyteWeb, :live_view

  def on_mount(:default, _params, session, socket) do
    case session["user_id"] do
      nil ->
        {:halt,
         socket
         |> put_flash(:error, gettext("Login required."))
         |> push_navigate(to: "/login")}

      user_id ->
        user = Exolyte.UserDB.get_user(user_id)
        {:cont, Phoenix.Component.assign(socket, :current_user, user)}
    end
  end
end
