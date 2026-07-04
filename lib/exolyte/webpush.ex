defmodule Exolyte.WebPush do
  def subscribe(user_id, endpoint) do
    GenServer.cast(Exolyte.WebPushServer, {:subscribe, user_id, endpoint})
  end

  def unsubscribe(user_id, endpoint) do
    GenServer.cast(Exolyte.WebPushServer, {:unsubscribe, user_id, endpoint})
  end

  def notify(user_id, content) do
    user = Exolyte.UserDB.get_user(user_id)
    GenServer.cast(Exolyte.WebPushServer, {:webpush, user_id, content})

    if user.unifiedpush_endpoint do
      # TODO:
      # handle_castにする必要があるもの
      # 戻り値の扱いはイメージなので、適切に書き換える必要がある
      case GenServer.cast(Exolyte.WebPushServer, {:unifiedpush, user_id, user.unifiedpush_endpoint, content}) do
        :ok -> :ok
        {:error, :invalid} ->
          Exolyte.UserDB.unsubscribe_unifiedpush(user_id)
        error -> error
      end
    end
  end

  def convert_notification_content(content) do
    title = case content.type do
      :invitation -> "Invited to channel"
      :mention -> "Mentioned"
      _ -> "Unknown notification"
    end

    text = case content.type do
      :invitation -> "You ware invited to channel #{content.channel_id}"
      :mention -> "You were mentioned on the #{content.channel_id} channel"
      _ -> "Something call you"
    end
  end
end
