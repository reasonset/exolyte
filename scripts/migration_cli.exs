# scripts/migration_cli.exs
alias Exolyte.UserDB
alias Exolyte.ChannelDB

case System.argv() do
  ["user"] ->
    defaults = %{
      blocked_channels: MapSet.new(),
      unifiedpush_endpoint: nil,
      notify_all_dms: false, # Existing users: false (Same as before), New users: true (Same as standard behavior)
      play_sound: true,
      created_at: DateTime.to_unix(~U[2000-01-01 00:00:00Z]),
      created_at_iso: DateTime.to_iso8601(~U[2000-01-01 00:00:00Z])
    }
    keys_to_migrate = ["blocked_channels", "last_notification_read_at", "notify_all_dms", "play_sound"]

    UserDB.list_users()
    |> Enum.each(fn {{:user, id}, data} ->
      IO.puts "For #{id}"

      # Migrate specific string keys to atom keys
      data =
        Enum.reduce(keys_to_migrate, data, fn key, acc ->
          if Map.has_key?(acc, key) do
            val = Map.get(acc, key)
            atom_key = String.to_atom(key)
            acc
            |> Map.put(atom_key, val)
            |> Map.delete(key)
          else
            acc
          end
        end)

      new_data = Map.merge(defaults, data)
      UserDB.update_user(id, new_data)
    end)

  ["channel"] ->
    defaults = %{
      banned_users: MapSet.new(),
      chop: nil,
      created_at: DateTime.to_unix(~U[2000-01-01 00:00:00Z]),
      created_at_iso: DateTime.to_iso8601(~U[2000-01-01 00:00:00Z])
    }
    ChannelDB.list_channels()
    |> Enum.each(fn {{:channel, id}, data} ->
      IO.puts "For #{id}"
      new_data = Map.merge(defaults, data)
      ChannelDB.update_channel(id, new_data)
    end)
end