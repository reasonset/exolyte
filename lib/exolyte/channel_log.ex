defmodule Exolyte.ChannelLog do
  @base_dir "logs"
  @threshold 500

  defp initial_collection do
    now = DateTime.utc_now
    %{
      messages: [],
      created_at: DateTime.to_unix(now),
      created_at_iso: DateTime.to_iso8601(now)
    }
  end

  def create_log_dir(channel_id) do
    dir = Path.join(@base_dir, channel_id)
    File.mkdir_p!(dir)

    File.write!(
      Path.join(dir, "collection-1.json"),
      Jason.encode!(initial_collection(), pretty: true)
    )
  end

  def create_message(content) do
    timestamp = System.os_time(:second)

    Map.merge(content, %{
      "timestamp" => timestamp
    })
  end

  def append_message(channel_id, content) do
    %{latest: latest} = Exolyte.ChannelDB.get_channel(channel_id)
    path = Path.join([@base_dir, channel_id, "collection-#{latest}.json"])
    {:ok, raw} = File.read(path)
    log = Jason.decode!(raw)

    message = create_message(content)

    updated_log = Map.update!(log, "messages", fn messages ->
      messages ++ [message]
    end)

    File.write!(path, Jason.encode!(updated_log, pretty: true))

    if length(updated_log["messages"]) >= @threshold do
      next = latest + 1
      new_path = Path.join([@base_dir, channel_id, "collection-#{next}.json"])
      File.write!(new_path, Jason.encode!(initial_collection(), pretty: true))
      Exolyte.ChannelDB.update_channel(channel_id, %{latest: next})
    end

    updated_log
  end

  def deliver_log(channel_id, :latest) do
    case Exolyte.ChannelDB.get_channel(channel_id) do
      nil -> {:error, :channel_not_found}
      %{latest: latest} -> deliver_log(channel_id, latest)
    end
  end

  def deliver_log(channel_id, log_index) do
    path = Path.join([@base_dir, channel_id, "collection-#{log_index}.json"])
    if File.exists?(path)
      {:ok, path}
    else
      {:error, :log_not_found}
    end
  end
end
