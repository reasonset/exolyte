# scripts/migration_cli.exs
alias Exolyte.UserDB
alias Exolyte.ChannelDB

case System.argv() do
  ["user"] ->
    defaults = %{
      "blocked_channels" => MapSet.new(),
      "created_at" => DateTime.to_unix(~U[2000-01-01 00:00:00Z]),
      "created_at_iso" => DateTime.to_iso8601(~U[2000-01-01 00:00:00Z])
    }
    UserDB.list_users()
    |> Enum.each(fn {{:user, id}, data} ->
      IO.puts "For #{id}"
      new_data = Map.merge(defaults, data)
      UserDB.update_user(id, new_data)
    end)

  ["channel"] ->
    defaults = %{
      "banned_users" => MapSet.new(),
      "chop" => nil,
      "created_at" => DateTime.to_unix(~U[2000-01-01 00:00:00Z]),
      "created_at_iso" => DateTime.to_iso8601(~U[2000-01-01 00:00:00Z])
    }
    ChannelDB.list_channels()
    |> Enum.each(fn {{:channel, id}, data} ->
      IO.puts "For #{id}"
      new_data = Map.merge(defaults, data)
      ChannelDB.update_channel(id, new_data)
    end)
end