defmodule Exolyte.WebPush do
  def subscribe(user_id, subscription) do
    GenServer.cast(Exolyte.WebPushServer, {:subscribe, user_id, subscription})
  end

  def unsubscribe(user_id, endpoint) do
    GenServer.cast(Exolyte.WebPushServer, {:unsubscribe, user_id, endpoint})
  end

  def get_vapid_details do
    db = Exolyte.DB.get_db()
    case CubDB.get(db, {:webpush_vapid, :keys}) do
      nil ->
        {public, private} = :crypto.generate_key(:ecdh, :prime256v1)
        public_b64 = Base.url_encode64(public, padding: false)
        private_b64 = Base.url_encode64(private, padding: false)
        keys = %{
          subject: "mailto:admin@localhost",
          public_key: public_b64,
          private_key: private_b64
        }
        CubDB.put(db, {:webpush_vapid, :keys}, keys)
        keys
      keys -> keys
    end
  end

  def notify(user_id, content) do
    Task.start(fn ->
      user = Exolyte.UserDB.get_user(user_id)
      GenServer.cast(Exolyte.WebPushServer, {:webpush, user_id, content})

      if user.unifiedpush_endpoint do
        converted = convert_notification_content(content)
        endpoint = user.unifiedpush_endpoint

        case Req.post(endpoint, body: converted.text) do
          {:ok, %Req.Response{status: status}} when status in 200..299 ->
            :ok
          {:ok, %Req.Response{status: status}} when status in 400..599 ->
            # Unsubscribe if the endpoint returns an error like 404/410
            Exolyte.UserDB.unsubscribe_unifiedpush(user_id)
          {:error, _} ->
            :error
        end
      end
    end)
  end

  def convert_notification_content(item) do
    title = case item.type do
      :invitation -> "Invited to channel"
      :mention -> "Mentioned"
      _ -> "Unknown notification"
    end

    channel_id = Map.get(item, :channel_id, "unknown")

    text = case item.type do
      :invitation -> "You were invited to channel #{channel_id}"
      :mention -> "You were mentioned: #{String.slice(item.content, 0, 50)}"
      _ -> "Something called you"
    end

    url = if channel_id != "unknown" do
      "/channel/#{channel_id}"
    else
      "/mypage"
    end

    %{
      title: title,
      text: text,
      url: url
    }
  end
end

