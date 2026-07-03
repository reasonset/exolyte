defmodule Exolyte.Notification do
  def read(user_id, channel_id) do
    db = Exolyte.NotificationCubDB.get_db()
    json = CubDB.get(db, {:notifications, user_id})
    data = if json, do: JSON.decode(json), else: %{}

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
    json = CubDB.get(db, {:notifications, user_id})
    if json, do: JSON.decode(json), else: %{}
  end
end
