admin_token = Application.get_env(:exolyte, :admin)[:token]
port = String.to_integer(System.get_env("PORT") || "4000")
headers = [
  {"Content-Type", "application/json"},
  {"X-Admin-Token", admin_token}
]

case System.argv() do
  ["channel_create", channel_id, name] ->
    body = %{
      "channel_id" => channel_id,
      "name" => name
    }

    url = "http://localhost:#{port}/admin/channel/create"
    IO.inspect(Req.post!(url, json: body, headers: headers))

  ["channel_join", channel_id, user_id] ->
    body = %{
      "user_id" => user_id,
      "channel_id" => channel_id
    }

    url = "http://localhost:#{port}/admin/channel/join"
    IO.inspect(Req.post!(url, json: body, headers: headers))

  ["user_create", user_id, display_name] ->
    length = 24
    password = :crypto.strong_rand_bytes(length)
               |> Base.url_encode64
               |> binary_part(0, length)

    body = %{
      "user_id" => user_id,
      "display_name" => display_name,
      "password" => password
    }

    url = "http://localhost:#{port}/admin/user/create"
    IO.puts(Req.post!(url, json: body, headers: headers).body)

  ["user_reset", user_id] ->
    body = %{
      "user_id" => user_id
    }

    url = "http://localhost:#{port}/admin/user/reset"
    IO.puts(Req.post!(url, json: body, headers: headers).body)

end