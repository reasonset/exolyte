defmodule ExolyteWeb.Plugs.SetLocale do
  import Plug.Conn

  def init(default), do: default

  def call(conn, _opts) do
    locale =
      conn.params["locale"] ||
      get_session(conn, :locale) ||
      get_req_header(conn, "accept-language") |> List.first() |> parse_locale() ||
      "en"

    Gettext.put_locale(ExolyteWeb.Gettext, locale)
    assign(conn, :locale, locale)
  end

  defp parse_locale(header) do
    # "ja,en;q=0.9" → "ja"
    String.split(header, ",") |> List.first()
  end
end
