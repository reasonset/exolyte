# scripts/user_cli.exs
alias Exolyte.ChannelDB

case System.argv() do
  ["create", id, name] ->
    ChannelDB.create_channel(id, name)
    IO.puts("Channel #{id} created.")

  ["get", id] ->
    case ChannelDB.get_channel(id) do
      nil -> IO.puts("Channel not found.")
      channel -> IO.inspect(channel)
    end

  ["delete", id] ->
    ChannelDB.delete_channel(id)
    IO.puts("Channel #{id} deleted.")

  ["adduser", id, user_id] ->
    ChannelDB.add_user(id, user_id)
    IO.puts("Added user #{user_id} to #{id}")

  ["deluser", id, user_id] ->
    ChannelDB.remove_user(id, user_id)
    IO.puts("Deleted user #{user_id} from #{id}")

  ["update", "name", id, name] ->
    ChannelDB.update_channel(id, %{name: name})
    IO.puts("Updated channel name of #{id}")

  ["update", "description", id, description] ->
    ChannelDB.update_channel(id, %{description: description})
    IO.puts("Updated channel description of #{id}")

  ["has", user_id] ->
    channels = ChannelDB.channels_for_user(user_id)
    IO.inspect(channels)

  ["list"] ->
    ChannelDB.list_channels()
    |> Enum.each(fn {{:channel, id}, data} ->
      IO.puts("#{id}: #{inspect(data)}")
    end)

  _ ->
    IO.puts("Usage: mix run scripts/channel_cli.exs [create|get|delete|adduser|deluser|update|list] ...")
end
