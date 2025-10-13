defmodule ExolyteWeb.PutLocale do
  use ExolyteWeb, :live_view

  def on_mount(:default, _params, session, socket) do
    locale = session["locale"] || "en"

    Gettext.put_locale(ExolyteWeb.Gettext, locale)
    {:cont, socket}
  end
end
