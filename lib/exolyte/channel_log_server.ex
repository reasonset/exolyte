defmodule ChannelLogServer do
  use GenServer
  require Logger

  def start_link(channel_id) do
    GenServer.start_link(__MODULE__, channel_id, name: via(channel_id))
  end

  defp via(channel_id), do: {:via, Registry, {ChatlogRegistry, channel_id}}

  def init(channel_id) do
    ref = schedule_shutdown()
    {:ok, {channel_id, ref}}
  end

  def handle_call({:update, content}, _from, {channel_id, old_ref}) do
    updated_log = Exolyte.ChannelLog.append_message(channel_id, content)

    Process.cancel_timer(old_ref)
    new_ref = schedule_shutdown()
    {:reply, updated_log, {channel_id, new_ref}}
  end

  def handle_info({:shutdown, ref}, {channel_id, current_ref}) when ref == current_ref do
    Logger.info("Shutting down ChannelLogServer #{channel_id}")
    {:stop, :normal, {channel_id, nil}}
  end

  def handle_info({:shutdown, _ref}, state) do
    {:noreply, state}
  end

  defp schedule_shutdown do
    ref = make_ref()
    Process.send_after(self(), {:shutdown, ref}, 30_000)
    ref
  end
end
