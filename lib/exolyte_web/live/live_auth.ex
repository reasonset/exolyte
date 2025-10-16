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
        user_theme = if Map.has_key?(user, :theme), do: user.theme, else: "kawaiifb"

        {:cont,
         socket
         |> assign(:current_user, user)
         |> assign(:user_id, user_id)
         |> assign(:user_theme, user_theme)}
    end
  end
end
