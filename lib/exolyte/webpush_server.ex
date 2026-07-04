defmodule Exolyte.WebPushServer do
  use GenServer
  
  def start_link(init \\ 0) do
    GenServer.start_link(__MODULE__, init, name: __MODULE__)
  end

  def init(state), do: {:ok, state}

  def handle_cast({:subscribe, user_id, endpoint}, _state) do
    db = Exolyte.WebPushCubDB.get_db()
    CubDB.update(db, {:webpush, user_id}, MapSet.new(), fn endpoint_set ->
      MapSet.put(endpoint_set, endpoint)
    end)
  end

  def handle_cast({:webpush, user_id, content}, _state) do
    db = Exolyte.WebPushCubDB.get_db()
    endpoints = CubDB.get(db, {:webpush, user_id}, MapSet.new())

    # TODO:
    # 各endpointに対してwebpushを行う
    # endpointが無効であった場合、unsubscribeを呼んで削除
  end

  def handle_cast({:unifiedpush, user_id, endpoint, content}, _state) do
    # TODO:
    # endpointに対してunifiedpushを行う
    # 問題なく行えれば:okを返す
    # 失敗した場合は {:error, error_type} を返す
    # 重要なのは、endpointが無効であった場合は {:error, :invalid} を返すこと
    # このため、handle_castにしてしまっているけど、handle_callに変更する必要がある
  end

  defp unsubscribe({user_id, endpoint}, _state) do
    db = Exolyte.WebPushCubDB.get_db()
    CubDB.update(db, {:webpush, user_id}, MapSet.new(), fn endpoint_set ->
      MapSet.delete(endpoint_set, endpoint)
    end)
  end
end