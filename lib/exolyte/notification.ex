defmodule Exolyte.Notification do
  def read(user_id, channel_id) do
    db = Exolyte.NotificationCubDB.get_db()
    data = CubDB.get(db, {:notifications, user_id}, %{})

    notifications = Map.get(data, channel_id)
    new_data = Map.delete(data, channel_id)
    CubDB.put(db, {:notifications, user_id}, new_data)

    notifications
  end

  def clear(user_id) do
    db = Exolyte.NotificationCubDB.get_db()
    CubDB.put(db, {:notifications, user_id}, %{})
  end

  def get(user_id) do
    db = Exolyte.NotificationCubDB.get_db()
    CubDB.get(db, {:notifications, user_id}, %{})
  end

  def channel_update(channel_id, timestamp) do
    GenServer.cast(Exolyte.NotificationServer, {:channel_update, channel_id, timestamp})
  end

  def unread?(:channel, user_id, channel_id) do
    db = Exolyte.NotificationCubDB.get_db()
    channel_last = CubDB.get(db, {:channel_update, channel_id}) || 0
    already_read = CubDB.get(db, {:message_received, user_id, channel_id}) || 0
    channel_last > already_read
  end

  def message_received(user_id, channel_id, timestamp) do
    GenServer.cast(Exolyte.NotificationServer, {:message_received, user_id, channel_id, timestamp})
  end

  def mention(user_id, channel_id, content) do
    GenServer.cast(Exolyte.NotificationServer, {:mention, user_id, channel_id, content})
  end

  def dm(user_id, channel_id, content) do
    GenServer.cast(Exolyte.NotificationServer, {:dm, user_id, channel_id, content})
  end

  def invitation(user_id, channel_id) do
    GenServer.cast(Exolyte.NotificationServer, {:invitation, user_id, channel_id})
  end
end
