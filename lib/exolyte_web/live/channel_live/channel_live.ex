defmodule ExolyteWeb.ChannelLive do
  use ExolyteWeb, :live_view

  def mount(%{"channel_id" => channel_id}, session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(Exolyte.PubSub, "channel:#{channel_id}")
      send(self(), "load_latest")
    end

    with channel_info when not is_nil(channel_info) <- Exolyte.ChannelDB.get_channel(channel_id),
         true <- MapSet.member?(channel_info.users, session["user_id"]) do
      channel_users =
        channel_info.users
        |> MapSet.to_list()
        |> Enum.map(fn user_id ->
          case Exolyte.UserDB.get_user(user_id) do
            nil ->
              nil

            user ->
              %{
                id: user.id,
                display_name: user.display_name,
                user_color: user.user_color
              }
          end
        end)
        |> Enum.reject(&is_nil/1)

      user_color_map = Map.new(channel_users, fn u -> {u.id, u.user_color} end)
      user_name_map = Map.new(channel_users, fn u -> {u.id, u.display_name} end)

      {:ok,
       socket
       |> assign(:channel_id, channel_id)
       |> assign(:channel_info, channel_info)
       |> assign(:channel_users, channel_users)
       |> assign(:channel_user_colors, user_color_map)
       |> assign(:channel_user_names, user_name_map)
       |> assign(:messages, [])
       |> assign(:oldest_index, nil)
       |> assign(:has_more, false)}
    else
      _ -> {:ok, push_navigate(socket, to: ~p"/not_found")}
    end
  end

  def render(assigns) do
    ~H"""
    <div class="drawer">
      <input id="channel-drawer" type="checkbox" class="drawer-toggle" />
      <div class="drawer-content flex flex-col h-dvh">
        <div class="navbar bg-base-100 shadow-sm">
          <label for="channel-drawer" class="btn drawer-button"><%= @channel_info.name %></label>
        </div>
        <div id="chat-messages" class="overflow-y-auto pb-20 flex-1" phx-hook="ChatContainerHook" data-oldest-index={@oldest_index} data-has-more={if @has_more, do: "true", else: "false"}>
          <%= for msg <- @messages do %>
            <div class={"chat #{if msg["user_id"] == @current_user.id, do: "chat-end", else: "chat-start"}"}>
            <div class="chat-header">
              <span style={"color: #{@channel_user_colors[msg["user_id"]]}"} class="text-sm"><%= @channel_user_names[msg["user_id"]] %></span>
              <time class="text-xs opacity-70">
                <%= format_time(msg["timestamp"]) %>
              </time>
            </div>
            <div class={"chat-bubble #{if msg["user_id"] == @current_user.id, do: "chat-bubble-primary", else: "chat-bubble-secondary"}"}>
              <%= raw(msg["content"]) %>
            </div>
          </div>
        <% end %>
        </div>
        <div class="bg-base-100 border-t p-3">
          <div>
            <form phx-submit="send_message" class="flex items-center gap-2" phx-hook="Keybinds" id="ChatForm">
              <textarea id="chat-input" placeholder="Something be good" class="textarea textarea-bordered flex-1 resize-none overflow-y-auto max-h-[30vh] h-auto min-h-0 font-mono" rows="1" phx-hook="AutoResize" name="content"></textarea>
              <button class="btn btn-primary" type="submit"><%= gettext("Chat!") %></button>
            </form>
          </div>
        </div>
      </div>
      <div class="drawer-side">
        <label for="channel-drawer" aria-label="close sidebar" class="drawer-overlay"></label>
        <ul class="menu bg-base-200 min-h-full w-80 p-4">
          <li><a href="/mypage" phx-link="navigate"><%= @current_user.display_name %></a></li>
          <ul class="menu bg-base-200 rounded-box">
            <%= for user <- @channel_users do %>
              <li style={"color: #{user.user_color}"}>
                <%= user.display_name %>
              </li>
            <% end %>
          </ul>
        </ul>
      </div>
    </div>
    """
  end

  def handle_info("load_latest", socket) do
    {:ok, path} =
      Exolyte.ChannelLog.deliver_log(socket.assigns.channel_id, :latest, socket.assigns.user_id)

    {:ok, raw} = File.read(path)
    log = Jason.decode!(raw)

    {:noreply,
     socket
     |> assign(:messages, format_messages(log["messages"]))
     |> assign(:oldest_index, log["index"])
     |> assign(:has_more, log["index"] > 1)}
  end

  def handle_info({:new_message, message}, socket) do
    if message["user_id"] == socket.assigns.user_id do
      {:noreply, socket}
    else
      {:noreply, assign(socket, :messages, socket.assigns.messages ++ [message])}
    end
  end

  def handle_event("load_more", _params, socket) do
    if socket.assigns.oldest_index > 1 do
      {:ok, path} =
        Exolyte.ChannelLog.deliver_log(
          socket.assigns.channel_id,
          socket.assigns.oldest_index - 1,
          socket.assigns.user_id
        )

      {:ok, raw} = File.read(path)
      log = Jason.decode!(raw)

      {:noreply,
       socket
       |> assign(:messages, format_messages(log["messages"]) ++ socket.assigns.messages)
       |> assign(:oldest_index, log["index"])}
    else
      {:noreply, socket}
    end
  end

  def handle_event("send_message", %{"content" => content}, socket) do
    chat = %{
      "user_id" => socket.assigns.user_id,
      "content" => content
    }

    message = format_message(Exolyte.ChannelLog.append_message(socket.assigns.channel_id, chat))

    Phoenix.PubSub.broadcast(
      Exolyte.PubSub,
      "channel:#{socket.assigns.channel_id}",
      {:new_message, message}
    )

    {:noreply, assign(socket, :messages, socket.assigns.messages ++ [message])}
  end

  defp format_time(unix_ts) do
    unix_ts
    |> DateTime.from_unix!()
    |> Calendar.strftime("%x %H:%M")
  end

  defp format_messages(messages) do
    Enum.map(messages, fn message ->
      format_message(message)
    end)
  end

  defp format_message(message) do
    message_marked =
      message["content"]
      |> HtmlSanitizeEx.basic_html()
      |> Earmark.as_html!(gfm: true)

    Map.put(message, "content", message_marked)
  end
end
