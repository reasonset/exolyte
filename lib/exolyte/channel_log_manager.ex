defmodule ChannelLogManager do
  def update(channel_id, content) do
    case Registry.lookup(ChatlogRegistry, channel_id) do
      [] ->
        spec = %{
          id: ChannelLogServer,
          start: {ChannelLogServer, :start_link, [channel_id]},
          restart: :temporary
        }

        DynamicSupervisor.start_child(ChatlogSupervisor, spec)
        GenServer.call(via(channel_id), {:update, content})

      [{pid, _}] ->
        GenServer.call(pid, {:update, content})
    end
  end

  defp via(channel_id), do: {:via, Registry, {ChatlogRegistry, channel_id}}
end
