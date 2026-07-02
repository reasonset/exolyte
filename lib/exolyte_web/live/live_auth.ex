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

        if Map.get(user, :frozen, false) do
          {:halt,
           socket
           |> put_flash(:error, gettext("Account is invalid."))
           |> push_navigate(to: "/login")}
        else
          user_theme = if Map.has_key?(user, :theme), do: user.theme, else: "kawaiifb"
          session_id = Base.encode16(:crypto.strong_rand_bytes(16))

          {:cont,
           socket
           |> assign(:current_user, user)
           |> assign(:user_id, user_id)
           |> assign(:user_theme, user_theme)
           |> assign(:session_id, session_id)}
        end
    end
  end
end
