defmodule Exolyte.ChannelDB do
  def create_channel(id, name) do
    db = Exolyte.DB.get_db()
    channel_data = %{
      id: id,
      name: name,
      description: "",
      users: MapSet.new(),
      latest: 1
    }

    :ok = CubDB.put(db, {:channel, id}, channel_data)

    try do
      Exolyte.ChannelLog.create_log_dir(id)
      :ok
    rescue
      e in File.Error ->
        CubDB.delete(db, {:channel, id})
        {:error, {:log_dir_failed, e}}
    end
  end

  def get_channel(id) do
    db = Exolyte.DB.get_db()
    CubDB.get(db, {:channel, id})
  end

  def update_channel(id, attrs) do
    db = Exolyte.DB.get_db()
    case get_channel(id) do
      nil -> {:error, :not_found}
      channel -> CubDB.put(db, {:channel, id}, Map.merge(channel, attrs))
    end
  end

  def delete_channel(id) do
    db = Exolyte.DB.get_db()
    CubDB.delete(db, {:channel, id})
  end

  def add_user(id, user_id) do
    db = Exolyte.DB.get_db()
    case get_channel(id) do
      nil -> {:error, :not_found}
      channel ->
        updated_users = MapSet.put(channel.users, user_id)
        updated = %{channel | users: updated_users}
        CubDB.put(db, {:channel, id}, updated)
    end
  end

  def remove_user(id, user_id) do
    db = Exolyte.DB.get_db()
    case get_channel(id) do
      nil -> {:error, :not_found}
      channel ->
        updated_users = MapSet.delete(channel.users, user_id)
        updated = %{channel | users: updated_users}
        CubDB.put(db, {:channel, id}, updated)
    end
  end

  def member?(id, user_id) do
    case get_channel(id) do
      nil -> false
      %{users: users} -> MapSet.member?(users, user_id)
    end
  end

  def channels_for_user(user_id) do
    list_channels()
    |> Enum.filter(fn {{:channel, _id}, %{users: users}} ->
      MapSet.member?(users, user_id)
    end)
  end

  def list_channels() do
    db = Exolyte.DB.get_db()
    CubDB.select(db, keys: :all)
    |> Enum.filter(fn
      {{:channel, _id}, _value} -> true
      _ -> false
    end)
  end
end
