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
    json = CubDB.get(db, {:notifications, user_id})
    data = if json, do: JSON.decode!(json), else: %{}
  
    item = %{
      type: :mention,
      content: content
    }

    CubDB.put(db, {:notifications, user_id}, data
    |> Map.update(channel_id, [item], fn existing_list ->
      [item | existing_list]
    end))

    {:noreply, nil}
  end

  def handle_cast({:invitation, user_id, channel_id}, _state) do
    db = Exolyte.NotificationCubDB.get_db()
    json = CubDB.get(db, {:notifications, user_id})
    data = if json, do: JSON.decode!(json), else: %{}

    item = %{
      type: :invitation,
      content: %{
        timestamp: System.os_time(:second)
      }
    }
    
    CubDB.put(db, {:notifications, user_id}, data
    |> Map.update(channel_id, [item], fn existing_list ->
      [item | existing_list]
    end))

    {:noreply, nil}
  end
end
