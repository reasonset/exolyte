defmodule ExolyteWeb.ChannelLive do
  use ExolyteWeb, :live_view

  def mount(%{"channel_id" => channel_id}, session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(Exolyte.PubSub, "channel:#{channel_id}")
      Registry.register(Exolyte.ChannelViewerRegistry, channel_id, session["user_id"])
      send(self(), "load_latest")
    end

    with channel_info when not is_nil(channel_info) <- Exolyte.ChannelDB.get_channel(channel_id),
         true <- MapSet.member?(channel_info.users, session["user_id"]) do
      ssocket = set_channel_info(channel_info, socket)
      settings = Exolyte.Settings.get()
      is_dm = String.starts_with?(channel_id, "dm:")

      channel_name = if (is_dm)
      do
        "dm:" <> rest = channel_id
        [u1, u2] = String.split(rest, ":")
        other_user_id = if u1 == socket.assigns.current_user.id, do: u2, else: u1
        "DM for @#{other_user_id}"
      else
        channel_info.name
      end

      {:ok,
       ssocket
       |> assign(:channel_id, channel_id)
       |> assign(:channel_name, channel_name)
       |> stream(:messages, [], dom_id: fn msg -> "msg-#{msg["timestamp"]}-#{msg["user_id"]}" end)
       |> assign(:oldest_index, nil)
       |> assign(:has_more, false)
       |> assign(:search_result, nil)
       |> assign(:search_error, nil)
       |> assign(:kick_target, nil)
       |> assign(:is_dm, is_dm)
       |> assign(:page_title, "#{channel_name} - #{ Map.get(settings, "instance_name") || "Exolyte"}")}

    else
      _ -> {:ok, push_navigate(socket, to: ~p"/not_found")}
    end
  end

  def render(assigns) do
    ~H"""
    <div class="drawer">
      <input id="channel-drawer" type="checkbox" class="drawer-toggle" phx-update="ignore" />
      <div class="drawer-content flex flex-col h-dvh">
        <div class="navbar bg-base-100 shadow-sm">
          <label for="channel-drawer" class="btn drawer-button"><%= @channel_name %></label>
        </div>
        <div id="chat-messages" class="overflow-y-auto pb-20 flex-1" phx-hook="ChatContainerHook" data-oldest-index={@oldest_index} data-has-more={if @has_more, do: "true", else: "false"} phx-update="stream">
          <div :for={{dom_id, msg} <- @streams.messages} id={dom_id} class={"chat #{if msg["user_id"] == @current_user.id, do: "chat-end", else: "chat-start"}"}>
            <div class="chat-header">
              <span style={"color: #{Map.get(@channel_user_colors, msg["user_id"], "#999999")}"} class="text-sm item-center inline-flex leading-none">
              <%= if Map.get(@channel_user_names, msg["user_id"]) do %>
                <%= @channel_user_names[msg["user_id"]] %>
              <% else %>
                <del><%= msg["user_id"] %></del>
              <% end %>
              </span>
              <time class="text-xs opacity-70" data-timestamp={msg["timestamp"]}>
              </time>
            </div>
            <div class={"chat-bubble #{if msg["user_id"] == @current_user.id, do: "chat-bubble-primary", else: "chat-bubble-secondary"}"}>
              <%= raw(msg["content"]) %>
            </div>
          </div>
        </div>
        <div class="bg-base-100 border-t p-3">
          <div>
            <form phx-submit="send_message" class="flex items-center gap-2" phx-hook="Keybinds" id="ChatForm">
              <textarea id="chat-input" placeholder="Something be good" class="textarea textarea-bordered flex-1 resize-none overflow-y-auto max-h-[30vh] h-auto min-h-0 font-mono" rows="1" phx-hook="AutoResize" name="content" required></textarea>
              <button class="btn btn-primary" type="submit"><%= gettext("Chat!") %></button>
            </form>
          </div>
        </div>
      </div>
      <div class="drawer-side z-50">
        <label for="channel-drawer" aria-label="close sidebar" class="drawer-overlay"></label>
        <div class="menu bg-base-200 min-h-full w-80 p-4 flex flex-col">
          <ul>
            <li><a href="/mypage" phx-link="navigate"><%= @current_user.display_name %></a></li>
          </ul>

          <%= if @channel_info.description && String.trim(@channel_info.description) != "" do %>
            <div class="px-4 py-2 text-xs text-base-content/60 italic break-words whitespace-pre-wrap"><%= @channel_info.description %></div>
          <% end %>

          <ul class="menu bg-base-200 rounded-box flex-1 mt-2">
            <%= for user <- @channel_users do %>
              <li style={"color: #{user.user_color}"}>
                <%= user.display_name %> (@<%= user.id %>)
              </li>
            <% end %>
          </ul>

          <%= if not @is_dm do %>
            <div class="mt-4 border-t pt-4 border-base-300">
              <h3 class="text-sm font-bold mb-2"><%= gettext("Invite User") %></h3>
              <form phx-submit="search_user" class="flex gap-2">
                <input type="text" name="search_id" class="input input-sm input-bordered flex-grow min-w-0" placeholder={gettext("User ID")} required />
                <button type="submit" class="btn btn-sm btn-primary"><%= gettext("Search") %></button>
              </form>

              <%= if @search_error do %>
                <div class="text-error text-xs mt-2"><%= @search_error %></div>
              <% end %>

              <%= if @search_result do %>
                <div class="flex items-center justify-between bg-base-100 p-2 rounded-box mt-2 shadow-sm">
                  <div class="overflow-hidden">
                    <p class="font-bold text-sm truncate" style={"color: #{@search_result.user_color};"}><%= @search_result.display_name %></p>
                  </div>
                  <button phx-click="invite_user" phx-value-target_id={@search_result.id} class="btn btn-xs btn-success ml-2"><%= gettext("Invite") %></button>
                </div>
              <% end %>
            </div>
          <% end %>

          <div class="mt-auto flex flex-col gap-2 pt-4">
            <%= if @channel_info.chop == @current_user.id do %>
              <label for="settings-modal" class="btn btn-outline btn-info w-full"><%= gettext("Channel Settings") %></label>
            <% end %>
            <label for="leave-modal" class="btn btn-outline btn-warning w-full"><%= gettext("Leave channel") %></label>
            <label for="block-modal" class="btn btn-outline btn-error w-full"><%= gettext("Block channel") %></label>
          </div>
        </div>
      </div>

      <!-- Leave Channel Modal -->
      <input type="checkbox" id="leave-modal" class="modal-toggle" phx-update="ignore" />
      <div class="modal" role="dialog">
        <div class="modal-box">
          <h3 class="text-lg font-bold"><%= gettext("Leave channel") %></h3>
          <p class="py-4"><%= gettext("Are you sure you want to leave this channel?") %></p>
          <div class="modal-action">
            <label for="leave-modal" class="btn"><%= gettext("Cancel") %></label>
            <button class="btn btn-warning" phx-click="leave_channel"><%= gettext("Leave") %></button>
          </div>
        </div>
        <label class="modal-backdrop" for="leave-modal"><%= gettext("Close") %></label>
      </div>

      <!-- Block Channel Modal -->
      <input type="checkbox" id="block-modal" class="modal-toggle" phx-update="ignore" />
      <div class="modal" role="dialog">
        <div class="modal-box">
          <h3 class="text-lg font-bold"><%= gettext("Block channel") %></h3>
          <p class="py-4"><%= gettext("Are you sure you want to block this channel?") %></p>
          <div class="modal-action">
            <label for="block-modal" class="btn"><%= gettext("Cancel") %></label>
            <button class="btn btn-error" phx-click="block_channel"><%= gettext("Block") %></button>
          </div>
        </div>
        <label class="modal-backdrop" for="block-modal"><%= gettext("Close") %></label>
      </div>

      <!-- Channel Settings Modal -->
      <%= if @channel_info.chop == @current_user.id do %>
        <input type="checkbox" id="settings-modal" class="modal-toggle" phx-update="ignore" />
        <div class="modal" role="dialog">
          <div class="modal-box">
            <h3 class="text-lg font-bold mb-4"><%= gettext("Channel Settings") %></h3>
            
            <form phx-submit="update_settings" class="mb-6 flex flex-col gap-4">
              <div class="form-control w-full">
                <label class="label">
                  <span class="label-text font-bold"><%= gettext("Channel Name") %></span>
                  <span class="label-text-alt text-base-content/60"><%= gettext("2-32 chars") %></span>
                </label>
                <input type="text" name="channel_name" value={@channel_name} class="input input-bordered w-full" required minlength="2" maxlength="32" />
              </div>
              <div class="form-control w-full">
                <label class="label">
                  <span class="label-text font-bold"><%= gettext("Channel Description") %></span>
                  <span class="label-text-alt text-base-content/60"><%= gettext("Max 140 chars") %></span>
                </label>
                <textarea name="description" class="textarea textarea-bordered textarea-md w-full resize-none focus:textarea-primary focus:shadow-sm" maxlength="140" rows="3" placeholder={gettext("Describe the purpose of this channel...")}><%= @channel_info.description %></textarea>
                <div class="mt-3 flex justify-end">
                  <button type="submit" class="btn btn-sm btn-primary"><%= gettext("Save Settings") %></button>
                </div>
              </div>
            </form>

            <div class="divider"></div>

            <h4 class="font-bold mb-2"><%= gettext("Kick User") %></h4>
            <ul class="menu bg-base-200 rounded-box max-h-40 overflow-y-auto">
              <%= for user <- @channel_users do %>
                <%= if user.id != @current_user.id do %>
                  <li class="flex flex-row justify-between items-center pr-2">
                    <span class="flex-1"><%= user.display_name %></span>
                    <button class="btn btn-xs btn-error" phx-click="confirm_kick" phx-value-user_id={user.id}><%= gettext("Kick") %></button>
                  </li>
                <% end %>
              <% end %>
            </ul>

            <div class="modal-action mt-6">
              <label for="settings-modal" class="btn"><%= gettext("Close") %></label>
            </div>
          </div>
          <label class="modal-backdrop" for="settings-modal"><%= gettext("Close") %></label>
        </div>
      <% end %>

      <!-- Kick Confirmation Modal -->
      <div class={"modal #{if @kick_target, do: "modal-open", else: ""}"} role="dialog">
        <div class="modal-box">
          <h3 class="text-lg font-bold text-error"><%= gettext("Kick User") %></h3>
          <p class="py-4">
            <%= gettext("Are you sure you want to kick and ban %{user}?", user: Map.get(@channel_user_names, @kick_target, @kick_target)) %>
          </p>
          <div class="modal-action">
            <button class="btn" phx-click="cancel_kick"><%= gettext("Cancel") %></button>
            <button class="btn btn-error" phx-click="execute_kick"><%= gettext("Kick User") %></button>
          </div>
        </div>
      </div>
    </div>
    """
  end

  def handle_info("load_latest", socket) do
    {:ok, path} =
      Exolyte.ChannelLog.deliver_log(socket.assigns.channel_id, :latest, socket.assigns.user_id)

    {:ok, raw} = File.read(path)
    log = Jason.decode!(raw)

    Exolyte.Notification.message_received(socket.assigns.user_id, socket.assigns.channel_id, System.os_time(:second))

    {:noreply,
     socket
     |> stream(:messages, format_messages(log["messages"]))
     |> assign(:oldest_index, log["index"])
     |> assign(:has_more, log["index"] > 1)}
  end

  def handle_info({:new_message, message}, socket) do
    if message["user_id"] == socket.assigns.user_id do
      {:noreply, socket}
    else
      socket = push_event(socket, "sound_receive", %{})
      {:noreply, stream_insert(socket, :messages, message)}
    end
  end

  def handle_info({:new_message, message, sender_session_id}, socket) do
    Exolyte.Notification.message_received(socket.assigns.user_id, socket.assigns.channel_id, message["timestamp"])
    if sender_session_id == socket.assigns.session_id do
      {:noreply, socket}
    else
      socket = push_event(socket, "sound_receive", %{})
      {:noreply, stream_insert(socket, :messages, message)}
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

      socket =
        format_messages(log["messages"])
        |> Enum.reverse()
        |> Enum.reduce(socket, fn msg, acc ->
          stream_insert(acc, :messages, msg, at: 0)
        end)

      {:noreply,
       socket
       |> assign(:oldest_index, log["index"])}
    else
      {:noreply, socket}
    end
  end

  def handle_event("send_message", %{"content" => content}, socket) do
    if !content || String.length(String.trim(content)) < 1 do
      {:noreply, socket}
    else
      chat = %{
        "user_id" => socket.assigns.user_id,
        "content" => String.trim(content)
      }

      message = format_message(Exolyte.ChannelLog.append_message(socket.assigns.channel_id, chat))

      Phoenix.PubSub.broadcast(
        Exolyte.PubSub,
        "channel:#{socket.assigns.channel_id}",
        {:new_message, message, socket.assigns.session_id}
      )

      Exolyte.Notification.channel_update(socket.assigns.channel_id, message["timestamp"])

      mentions = parse_mentions(String.trim(content)) |> Enum.uniq()
      for user <- mentions do
        if MapSet.member?(socket.assigns.channel_info.users, user) do
          viewers = Registry.lookup(Exolyte.ChannelViewerRegistry, socket.assigns.channel_id)
          is_viewing? = Enum.any?(viewers, fn {_pid, viewer_user_id} -> viewer_user_id == user end)

          if not is_viewing? do
            Exolyte.Notification.mention(user, socket.assigns.channel_id, String.trim(content))
          end
        end
      end

      socket = push_event(socket, "sound_sent", %{})
      {:noreply, stream_insert(socket, :messages, message)}
    end
  end

  def handle_event("leave_channel", _params, socket) do
    Exolyte.ChannelDB.remove_user(socket.assigns.channel_id, socket.assigns.user_id)
    {:noreply, push_navigate(socket, to: ~p"/mypage")}
  end

  def handle_event("block_channel", _params, socket) do
    Exolyte.UserDB.block_channel(socket.assigns.user_id, socket.assigns.channel_id)
    {:noreply, push_navigate(socket, to: ~p"/mypage")}
  end

  def handle_event("search_user", %{"search_id" => search_id}, socket) do
    if String.starts_with?(socket.assigns.channel_id, "dm:") do
      {:noreply, socket}
    else
      normalized_id = String.downcase(String.trim(search_id))

      if normalized_id == socket.assigns.user_id do
        {:noreply,
         assign(socket, search_result: nil, search_error: gettext("Cannot invite yourself."))}
      else
        case Exolyte.UserDB.get_user(normalized_id) do
          nil ->
            {:noreply,
             assign(socket, search_result: nil, search_error: gettext("User not found."))}

          user ->
            if MapSet.member?(socket.assigns.channel_info.users, normalized_id) do
              {:noreply,
               assign(socket,
                 search_result: nil,
                 search_error: gettext("User is already in the channel.")
               )}
            else
              {:noreply, assign(socket, search_result: user, search_error: nil)}
            end
        end
      end
    end
  end

  def handle_event("invite_user", %{"target_id" => target_id}, socket) do
    if String.starts_with?(socket.assigns.channel_id, "dm:") do
      {:noreply, socket}
    else
      case Exolyte.UserDB.get_user(target_id) do
        nil ->
          {:noreply, assign(socket, search_error: gettext("User not found."))}

        user ->
          blocked = Map.get(user, "blocked_channels", MapSet.new())
          chop_id = socket.assigns.channel_info.chop

          blocked_chop_dm =
            if chop_id do
              dm_id = Exolyte.Friend.dm_channel_id(chop_id, target_id)
              MapSet.member?(blocked, dm_id)
            else
              false
            end

          cond do
            MapSet.member?(blocked, socket.assigns.channel_id) ->
              {:noreply, assign(socket, search_error: gettext("User has blocked this channel."))}

            blocked_chop_dm ->
              {:noreply, assign(socket, search_error: gettext("User has blocked the channel operator."))}

            true ->
              case Exolyte.ChannelDB.add_user(socket.assigns.channel_id, target_id) do
                {:ok, updated_channel} ->
                  Exolyte.Notification.invitation(target_id, socket.assigns.channel_id)
                  
                  {:noreply,
                   socket
                   |> set_channel_info(updated_channel)
                   |> assign(:search_result, nil)
                   |> assign(:search_error, nil)}

                {:error, :banned} ->
                  {:noreply,
                   assign(socket, search_error: gettext("User is banned from this channel."))}

                {:error, reason} ->
                  {:noreply,
                   assign(socket,
                     search_error:
                       gettext("Failed to invite user: %{reason}", reason: inspect(reason))
                   )}
              end
          end
      end
    end
  end

  def handle_event("update_settings", %{"description" => description, "channel_name" => channel_name}, socket) do
    if socket.assigns.current_user.id == socket.assigns.channel_info.chop do
      safe_desc = String.slice(description, 0, 140)
      safe_name = String.slice(channel_name, 0, 32)
      
      Exolyte.ChannelDB.update_channel(socket.assigns.channel_id, %{description: safe_desc, name: safe_name})
      updated_channel = Exolyte.ChannelDB.get_channel(socket.assigns.channel_id)
      
      {:noreply, set_channel_info(updated_channel, socket)}
    else
      {:noreply, socket}
    end
  end

  def handle_event("confirm_kick", %{"user_id" => target_id}, socket) do
    if socket.assigns.current_user.id == socket.assigns.channel_info.chop do
      {:noreply, assign(socket, kick_target: target_id)}
    else
      {:noreply, socket}
    end
  end

  def handle_event("cancel_kick", _params, socket) do
    {:noreply, assign(socket, kick_target: nil)}
  end

  def handle_event("execute_kick", _params, socket) do
    target_id = socket.assigns.kick_target

    if target_id && socket.assigns.current_user.id == socket.assigns.channel_info.chop do
      case Exolyte.ChannelDB.ban_user(socket.assigns.channel_id, target_id) do
        {:ok, updated_channel} ->
          {:noreply, 
           socket
           |> set_channel_info(updated_channel)
           |> assign(:kick_target, nil)}
        _ ->
          {:noreply, assign(socket, kick_target: nil)}
      end
    else
      {:noreply, assign(socket, kick_target: nil)}
    end
  end

  defp format_messages(messages) do
    Enum.map(messages, fn message ->
      format_message(message)
    end)
  end

  defp format_message(message) do
    content = message["content"]
    mentions = parse_mentions(content) |> Enum.uniq()

    message_marked =
      content
      |> MDEx.to_html!(
        extension: [table: true, tasklist: true, strikethrough: true, autolink: true]
      )

    message_styled = Enum.reduce(mentions, message_marked, fn user, acc ->
      String.replace(acc, ~r/(^|\s|>)(@#{user})($|\s|<)/, "\\1<span class=\"bg-base-100 text-base-content font-bold px-1 rounded shadow-sm\">\\2</span>\\3")
    end)

    Map.put(message, "content", message_styled)
  end

  defp parse_mentions(content) do
    lines = String.split(content, ~r/\r\n|\n|\r/)
    first_line = List.first(lines) || ""

    if String.trim(first_line) == "" do
      []
    else
      Enum.reduce_while(lines, [], fn line, acc ->
        if String.trim(line) == "" do
          {:halt, acc}
        else
          tokens = String.split(line)
          {mentions, rest} = Enum.split_while(tokens, fn token ->
            Regex.match?(~r/^@[a-zA-Z0-9_]+$/, token)
          end)

          extracted = Enum.map(mentions, fn "@" <> user -> user end)

          if rest == [] do
            {:cont, acc ++ extracted}
          else
            {:halt, acc ++ extracted}
          end
        end
      end)
    end
  end

  defp set_channel_info(channel_info, socket) do
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

    socket
    |> assign(:channel_info, channel_info)
    |> assign(:channel_users, channel_users)
    |> assign(:channel_user_colors, user_color_map)
    |> assign(:channel_user_names, user_name_map)
  end
end
