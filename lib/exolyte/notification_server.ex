defmodule Exolyte.NotificationServer do
  use GenServer
  
  def start_link(init \\ 0) do
    GenServer.start_link(__MODULE__, init, name: __MODULE__)
  end

  def init(state), do: {:ok, state}

  def handle_cast({:channel_update, channel_id, timestamp}, _state) do
    db = Exolyte.NotificationCubDB.get_db()
    CubDB.put(db, {:channel_update, channel_id}, timestamp)    
    {:noreply, nil}
  end

  def handle_cast({:message_received, user_id, channel_id, timestamp}, _state) do
    db = Exolyte.NotificationCubDB.get_db()
    CubDB.put(db, {:message_received, user_id, channel_id}, timestamp)
    {:noreply, nil}
  end

  def handle_cast({:mention, user_id, channel_id, content}, _state) do
    db = Exolyte.NotificationCubDB.get_db()
  
    item = %{
      type: :mention,
      content: content,
      channel_id: channel_id,
      timestamp: System.os_time(:second)
    }

    CubDB.update(db, {:notifications, user_id}, %{channel_id => [item]}, fn data ->
      Map.update(data, channel_id, [item], fn existing_list ->
        [item | existing_list]
      end)
    end)

    Exolyte.WebPush.notify(user_id, item)

    {:noreply, nil}
  end

  def handle_cast({:dm, user_id, channel_id, content}, _state) do
    user_data = Exolyte.UserDB.get_user(user_id)
    notify_all_dms = if user_data do
      Map.get(user_data, :notify_all_dms, Map.get(user_data, "notify_all_dms", true))
    else
      true
    end

    if notify_all_dms do
      db = Exolyte.NotificationCubDB.get_db()
    
      item = %{
        type: :dm,
        content: content,
        channel_id: channel_id,
        timestamp: System.os_time(:second)
      }

      CubDB.update(db, {:notifications, user_id}, %{channel_id => [item]}, fn data ->
        Map.update(data, channel_id, [item], fn existing_list ->
          [item | existing_list]
        end)
      end)

      Exolyte.WebPush.notify(user_id, item)
    end

    {:noreply, nil}
  end

  def handle_cast({:invitation, user_id, channel_id}, _state) do
    db = Exolyte.NotificationCubDB.get_db()

    item = %{
      type: :invitation,
      channel_id: channel_id,
      timestamp: System.os_time(:second),
      content: %{
        timestamp: System.os_time(:second),
        channel_id: channel_id
      }
    }
    
    CubDB.update(db, {:notifications, user_id}, %{channel_id => [item]}, fn data ->
      Map.update(data, channel_id, [item], fn existing_list ->
        [item | existing_list]
      end)
    end)

    Exolyte.WebPush.notify(user_id, item)

    {:noreply, nil}
  end
end
