defmodule Exolyte.WebPushServer do
  use GenServer
  
  def start_link(init \\ 0) do
    GenServer.start_link(__MODULE__, init, name: __MODULE__)
  end

  def init(state) do
    # Fetch VAPID details to ensure they are generated and set in Application env
    Exolyte.WebPush.get_vapid_details()
    {:ok, state}
  end

  def handle_cast({:subscribe, user_id, subscription}, _state) do
    db = Exolyte.WebPushCubDB.get_db()
    # subscription is a map: %{"endpoint" => _, "keys" => %{"auth" => _, "p256dh" => _}}
    endpoint = subscription["endpoint"]
    
    CubDB.update(db, {:webpush, user_id}, %{}, fn endpoint_map ->
      Map.put(endpoint_map, endpoint, subscription)
    end)
    {:noreply, nil}
  end

  def handle_cast({:webpush, user_id, content}, _state) do
    db = Exolyte.WebPushCubDB.get_db()
    subscriptions = CubDB.get(db, {:webpush, user_id}, %{})
    
    _vapid_details = Exolyte.WebPush.get_vapid_details()
    converted = Exolyte.WebPush.convert_notification_content(content)
    payload = Jason.encode!(converted)

    Enum.each(subscriptions, fn {endpoint, sub} ->
      web_push_sub = %{
        "keys" => %{
          "auth" => sub["keys"]["auth"],
          "p256dh" => sub["keys"]["p256dh"]
        },
        "endpoint" => endpoint
      }
      
      case WebPushElixir.send_notification(web_push_sub, payload) do
        {:ok, _response} ->
          :ok
        {:error, :expired} ->
          unsubscribe({user_id, endpoint}, nil)
        {:error, {:http_error, status, _body}} when status in 400..499 ->
          unsubscribe({user_id, endpoint}, nil)
        {:error, _} ->
          :error
      end
    end)
    {:noreply, nil}
  end

  def handle_cast({:unsubscribe, user_id, endpoint}, _state) do
    unsubscribe({user_id, endpoint}, nil)
    {:noreply, nil}
  end

  defp unsubscribe({user_id, endpoint}, _state) do
    db = Exolyte.WebPushCubDB.get_db()
    CubDB.update(db, {:webpush, user_id}, %{}, fn endpoint_map ->
      Map.delete(endpoint_map, endpoint)
    end)
  end
end