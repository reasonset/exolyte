defmodule ExolyteWeb.PutLocale do
  import Phoenix.LiveView
  use ExolyteWeb, :live_view

  def on_mount(:default, _params, session, socket) do
    IO.puts(session["locale"])
    locale = session["locale"] || "en"

    Gettext.put_locale(ExolyteWeb.Gettext, locale)
    {:cont, socket}
  end
end
