defmodule ExolyteWeb.UserLive.Show do
  use ExolyteWeb, :live_view

  @themes MapSet.new(["kawaiifb", "synthwave", "coffee", "winter", "dark", "light"])

  def mount(_params, session, socket) do
    user_id = session["user_id"]
    channels =
      Exolyte.ChannelDB.channels_for_user(user_id)
      |> Enum.map(fn channel ->
        marks = []

        marks =
          if Exolyte.Notification.unread?(:channel, user_id, channel.id) do
            [:unread | marks]
          else
            marks
          end

        Map.put(channel, :unread_marks, Enum.reverse(marks))
      end)

    user = Exolyte.UserDB.get_user(user_id)
    blocked_channels = Map.get(user, "blocked_channels", MapSet.new()) |> MapSet.to_list()

    {dm_channels, regular_channels} =
      Enum.split_with(channels, fn
        %{id: "dm:" <> _} -> true
        _ -> false
      end)

    settings = Exolyte.Settings.get()

    notifications_map = Exolyte.Notification.get(user_id)
    notifications =
      notifications_map
      |> Map.values()
      |> List.flatten()
      |> Enum.sort_by(& &1.timestamp, :desc)

    last_notification_read_at = Map.get(user, "last_notification_read_at", 0)
    unread_count = Enum.count(notifications, fn item -> item.timestamp > last_notification_read_at end)

    {:ok,
     socket
     |> assign(:user_id, user_id)
     |> assign(:regular_channels, regular_channels)
     |> assign(:dm_channels, dm_channels)
     |> assign(:blocked_channels, blocked_channels)
     |> assign(:unblock_target, nil)
     |> assign(:search_result, nil)
     |> assign(:search_error, nil)
     |> assign(:settings, settings)
     |> assign(:notifications, notifications)
     |> assign(:last_notification_read_at, last_notification_read_at)
     |> assign(:unread_count, unread_count)
     |> assign(:generated_link, nil)
     |> assign(:generated_qr, nil)
     |> assign(:channel_error, nil)
     |> assign(:current_user, user)
     |> assign(:vapid_public_key, Exolyte.WebPush.get_vapid_details().public_key)
     |> assign(:page_title, "MyPage - #{ Map.get(settings, "instance_name") || "Exolyte"}")}
  end

  def render(assigns) do
    ~H"""
    <div class="max-w-xl mx-auto mt-10">
      <div class="navbar bg-base-100 shadow-xl rounded-box mb-4 px-4">
        <div class="flex-1">
          <a class="text-xl font-bold">Exolyte</a>
        </div>
        <div class="flex-none">
          <div class="dropdown dropdown-end">
            <div tabindex="0" role="button" class="btn btn-ghost btn-circle" phx-click="open_notifications">
              <div class="indicator">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 17h5l-1.405-1.405A2.032 2.032 0 0118 14.158V11a6.002 6.002 0 00-4-5.659V5a2 2 0 10-4 0v.341C7.67 6.165 6 8.388 6 11v3.159c0 .538-.214 1.055-.595 1.436L4 17h5m6 0v1a3 3 0 11-6 0v-1m6 0H9" /></svg>
                <%= if @unread_count > 0 do %>
                  <span class="badge badge-xs badge-primary indicator-item"><%= @unread_count %></span>
                <% end %>
              </div>
            </div>
            <div tabindex="0" class="mt-3 z-[1] card card-compact dropdown-content w-80 bg-base-200 shadow-xl border border-base-300">
              <div class="card-body max-h-96 overflow-y-auto">
                <div class="flex justify-between items-center mb-2">
                  <h3 class="font-bold text-lg"><%= gettext("Notifications") %></h3>
                  <%= if length(@notifications) > 0 do %>
                    <button class="btn btn-xs btn-outline btn-error" phx-click="clear_notifications"><%= gettext("Clear All") %></button>
                  <% end %>
                </div>
                
                <%= if length(@notifications) == 0 do %>
                  <p class="text-base-content/60"><%= gettext("No notifications.") %></p>
                <% else %>
                  <ul class="menu bg-base-100 w-full p-0 rounded-box overflow-hidden">
                    <%= for item <- @notifications do %>
                      <% is_unread = item.timestamp > @last_notification_read_at %>
                      <li class={if is_unread, do: "bg-base-300 border-l-4 border-primary", else: "border-l-4 border-transparent"}>
                        <a href={"/channel/#{item.channel_id}"} class="flex flex-col items-start gap-1 p-3">
                          <span class="text-xs text-base-content/60"><%= format_time(item.timestamp) %></span>
                          <%= case item.type do %>
                            <% :invitation -> %>
                              <span class="font-bold text-sm"><%= gettext("Invited to channel: %{channel}", channel: item.channel_id) %></span>
                            <% :mention -> %>
                              <span class="font-bold text-sm"><%= gettext("Mentioned in %{channel}", channel: item.channel_id) %></span>
                              <span class="text-xs truncate w-full text-base-content/80"><%= item.content %></span>
                          <% end %>
                        </a>
                      </li>
                    <% end %>
                  </ul>
                <% end %>
              </div>
            </div>
          </div>
        </div>
      </div>

      <div class="card bg-base-100 shadow-xl mb-4">
        <div class="card-body">
          <h2 class="card-title text-xl"><%= gettext("Add Friend") %></h2>
          <form phx-submit="search_user" class="flex gap-2">
            <input type="text" name="search_id" class="input input-bordered flex-grow" placeholder={gettext("Enter User ID to search")} required />
            <button type="submit" class="btn btn-primary"><%= gettext("Search") %></button>
          </form>

          <%= if @search_error do %>
            <div class="text-error mt-2"><%= @search_error %></div>
          <% end %>

          <%= if @search_result do %>
            <div class="flex items-center justify-between bg-base-200 p-4 rounded-box mt-4">
              <div>
                <p class="font-bold" style={"color: #{@search_result.user_color};"}><%= @search_result.display_name %></p>
                <p class="text-sm text-base-content/70"><%= @search_result.id %></p>
              </div>
              <button phx-click="add_friend" phx-value-target_id={@search_result.id} class="btn btn-sm btn-success"><%= gettext("Add") %></button>
            </div>
          <% end %>
        </div>
      </div>

      <div class="card bg-base-100 shadow-xl">
        <div class="card-body">
          <h2 class="card-title text-2xl" style={"color: #{@current_user.user_color};"}><%= @current_user.display_name %></h2>

          <div class="mt-4">
            <p><span class="font-bold"><%= gettext("User ID") %>: </span><code><%= @user_id %></code></p>
          </div>

          <div class="mt-6">
            <h3 class="text-lg font-semibold mb-2"><%= gettext("Channels") %></h3>
            <ul class="menu bg-base-200 rounded-box">
              <%= for channel <- @regular_channels do %>
                  <li>
                    <a href={"/channel/#{channel.id}"} phx-link="navigate" class="flex justify-between items-center">
                      <span><%= channel.name %></span>
                      <div class="flex gap-1">
                        <%= for mark <- channel.unread_marks do %>
                          <%= if mark == :unread do %>
                            <span class="badge badge-primary badge-xs" title={gettext("Unread")}></span>
                          <% end %>
                        <% end %>
                      </div>
                    </a>
                  </li>
              <% end %>
            </ul>
          </div>

          <%= if length(@dm_channels) > 0 do %>
            <div class="mt-6">
              <h3 class="text-lg font-semibold mb-2"><%= gettext("Direct Messages") %></h3>
              <ul class="menu bg-base-200 rounded-box">
                <%= for channel <- @dm_channels do %>
                    <%
                      "dm:" <> rest = channel.id
                      [u1, u2] = String.split(rest, ":")
                      other_user_id = if u1 == @user_id, do: u2, else: u1
                    %>
                    <li>
                      <a href={"/channel/#{channel.id}"} phx-link="navigate" class="flex justify-between items-center">
                        <span>@<%= other_user_id %></span>
                        <div class="flex gap-1">
                          <%= for mark <- channel.unread_marks do %>
                            <%= if mark == :unread do %>
                              <span class="badge badge-primary badge-xs" title={gettext("Unread")}></span>
                            <% end %>
                          <% end %>
                        </div>
                      </a>
                    </li>
                <% end %>
              </ul>
            </div>
          <% end %>
        </div>
      </div>

      <div class="collapse bg-base-200 mt-4 border border-base-300">
        <input type="checkbox" /> 
        <div class="collapse-title text-xl font-medium">
          <%= gettext("Blocked Channels") %>
        </div>
        <div class="collapse-content">
          <%= if length(@blocked_channels) == 0 do %>
            <p><%= gettext("No blocked channels.") %></p>
          <% else %>
            <ul class="menu">
              <%= for channel_id <- @blocked_channels do %>
                <li class="flex flex-row justify-between items-center">
                  <span class="flex-1"><%= channel_id %></span>
                  <button phx-click="confirm_unblock" phx-value-channel_id={channel_id} class="btn btn-sm btn-outline btn-error ml-2">
                    <%= gettext("Unblock") %>
                  </button>
                </li>
              <% end %>
            </ul>
          <% end %>
        </div>
      </div>

      <fieldset class="fieldset bg-base-200 border-base-300 rounded-box w-xs border p-4 mt-4">
        <legend class="fieldset-legend">Settings</legend>
          <form phx-submit="update_user">
            <span class="label">Theme</span>
            <select class="select" name="theme_name">
              <option selected>kawaiifb</option>
              <option>synthwave</option>
              <option>coffee</option>
              <option>winter</option>
              <option>dark</option>
              <option>light</option>
            </select>
            <label class="label"><%= gettext("Display Name") %></label>
            <input type="text" class="input" placeholder={gettext("Display Name")} name="disp_name" value={@current_user.display_name} />
            <button class="btn btn-neutral mt-4" type="submit">save</button>
          </form>
          
          <div class="divider"></div>
          
          <form phx-submit="update_unifiedpush">
            <label class="label"><%= gettext("UnifiedPush Endpoint URL") %></label>
            <input type="url" class="input w-full" placeholder="https://..." name="endpoint" value={@current_user.unifiedpush_endpoint} />
            <button class="btn btn-neutral mt-4" type="submit"><%= gettext("Save UnifiedPush Endpoint") %></button>
          </form>

          <div class="divider"></div>
          
          <div id="webpush-container" phx-hook="WebPush" data-public-key={@vapid_public_key}>
            <button id="webpush-subscribe-btn" class="btn btn-primary w-full"><%= gettext("Enable WebPush Notifications") %></button>
            <p id="webpush-status" class="text-sm mt-2 text-center"></p>
          </div>
      </fieldset>

      <%= if Map.get(@settings, "allow_user_invites", false) do %>
        <fieldset class="fieldset bg-base-200 border-base-300 rounded-box w-xs border p-4 mt-4">
          <legend class="fieldset-legend"><%= gettext("Invite User") %></legend>
          <div class="text-sm text-base-content/70 mb-4">
            Generate a one-time link for a user to register their account. The link expires in 24 hours.
          </div>
          <button class="btn btn-primary w-full" phx-click="generate_link">Generate Link</button>
          
          <%= if @generated_link do %>
            <div class="mt-4 flex flex-col items-center gap-4 w-full">
              <div class="bg-white p-4 rounded-xl shadow-sm inline-block">
                <%= Phoenix.HTML.raw(@generated_qr) %>
              </div>
              <div class="form-control w-full">
                <input type="text" value={@generated_link} class="input input-sm input-bordered w-full" readonly />
              </div>
            </div>
          <% end %>
        </fieldset>
      <% end %>

      <%= if Map.get(@settings, "allow_channel_creation", false) do %>
        <fieldset class="fieldset bg-base-200 border-base-300 rounded-box w-xs border p-4 mt-4">
          <legend class="fieldset-legend"><%= gettext("Create Channel") %></legend>
          <form phx-submit="create_channel" class="flex flex-col gap-2">
            <div class="form-control">
              <label class="label"><%= gettext("Channel ID") %></label>
              <input type="text" name="channel_id" class="input w-full" placeholder="e.g. general_chat" required pattern="^[a-z][a-z0-9_]{4,30}[a-z0-9]$" title="Must be 6-32 chars, start with lowercase letter, end with lowercase letter or number, and contain only lowercase letters, numbers, and underscores." />
            </div>
            <div class="form-control">
              <label class="label"><%= gettext("Channel Name") %></label>
              <input type="text" name="channel_name" class="input w-full" placeholder="e.g. General Chat" required minlength="2" maxlength="32" />
            </div>
            <%= if @channel_error do %>
              <div class="text-error text-sm mt-2"><%= @channel_error %></div>
            <% end %>
            <button class="btn btn-primary mt-4 w-full" type="submit"><%= gettext("Create") %></button>
          </form>
        </fieldset>
      <% end %>

      <!-- Unblock Confirmation Modal -->
      <div class={"modal #{if @unblock_target, do: "modal-open", else: ""}"} role="dialog">
        <div class="modal-box">
          <h3 class="text-lg font-bold"><%= gettext("Unblock Channel") %></h3>
          <p class="py-4"><%= gettext("Are you sure you want to unblock %{channel}?", channel: @unblock_target) %></p>
          <div class="modal-action">
            <button class="btn" phx-click="cancel_unblock"><%= gettext("Cancel") %></button>
            <button class="btn btn-error" phx-click="execute_unblock"><%= gettext("Unblock") %></button>
          </div>
        </div>
      </div>

      <!-- Logout Button -->
      <div class="mt-8 flex justify-center">
        <.link href="/logout" method="delete" class="btn btn-outline btn-error w-full"><%= gettext("Logout") %></.link>
      </div>
    </div>
    """
  end

  def handle_event(
        "update_user",
        %{"disp_name" => display_name, "theme_name" => user_theme},
        socket
      ) do
    theme = if MapSet.member?(@themes, user_theme), do: user_theme, else: "kawaiifb"

    newsetting = %{display_name: display_name, theme: theme}
    Exolyte.UserDB.update_user(socket.assigns.user_id, newsetting)

    current_user = Map.merge(socket.assigns.current_user, newsetting)

    {:noreply,
     socket
     |> assign(:current_user, current_user)
     |> assign(:user_theme, theme)}
  end

  def handle_event("update_unifiedpush", %{"endpoint" => endpoint}, socket) do
    endpoint = String.trim(endpoint)
    endpoint = if endpoint == "", do: nil, else: endpoint
    
    Exolyte.UserDB.update_user(socket.assigns.user_id, %{unifiedpush_endpoint: endpoint})
    
    current_user = Map.put(socket.assigns.current_user, :unifiedpush_endpoint, endpoint)
    
    {:noreply, assign(socket, :current_user, current_user)}
  end

  def handle_event("webpush_subscribe", %{"subscription" => subscription}, socket) do
    Exolyte.WebPush.subscribe(socket.assigns.user_id, subscription)
    {:noreply, socket}
  end

  def handle_event("search_user", %{"search_id" => search_id}, socket) do
    normalized_id = String.downcase(String.trim(search_id))

    if normalized_id == socket.assigns.user_id do
      {:noreply,
       assign(socket, search_result: nil, search_error: gettext("Cannot add yourself."))}
    else
      case Exolyte.UserDB.get_user(normalized_id) do
        nil ->
          {:noreply, assign(socket, search_result: nil, search_error: gettext("User not found."))}

        user ->
          {:noreply, assign(socket, search_result: user, search_error: nil)}
      end
    end
  end

  def handle_event("add_friend", %{"target_id" => target_id}, socket) do
    case Exolyte.Friend.add_friend(socket.assigns.user_id, target_id) do
      {:ok, _channel_id} ->
        channels =
          Exolyte.ChannelDB.channels_for_user(socket.assigns.user_id)
          |> Enum.map(fn channel ->
            marks = []

            marks =
              if Exolyte.Notification.unread?(:channel, socket.assigns.user_id, channel.id) do
                [:unread | marks]
              else
                marks
              end

            Map.put(channel, :unread_marks, Enum.reverse(marks))
          end)

        {dm_channels, regular_channels} =
          Enum.split_with(channels, fn
            %{id: "dm:" <> _} -> true
            _ -> false
          end)

        {:noreply,
         socket
         |> assign(:search_result, nil)
         |> assign(:search_error, nil)
         |> assign(:regular_channels, regular_channels)
         |> assign(:dm_channels, dm_channels)}

      {:error, reason} ->
        {:noreply,
         assign(socket,
           search_error: gettext("Failed to add friend: %{reason}", reason: inspect(reason))
         )}
    end
  end

  def handle_event("confirm_unblock", %{"channel_id" => channel_id}, socket) do
    {:noreply, assign(socket, :unblock_target, channel_id)}
  end

  def handle_event("cancel_unblock", _params, socket) do
    {:noreply, assign(socket, :unblock_target, nil)}
  end

  def handle_event("execute_unblock", _params, socket) do
    if socket.assigns.unblock_target do
      Exolyte.UserDB.unblock_channel(socket.assigns.user_id, socket.assigns.unblock_target)

      user = Exolyte.UserDB.get_user(socket.assigns.user_id)
      blocked_channels = Map.get(user, "blocked_channels", MapSet.new()) |> MapSet.to_list()

      {:noreply, assign(socket, unblock_target: nil, blocked_channels: blocked_channels)}
    else
      {:noreply, socket}
    end
  end

  def handle_event("generate_link", _params, socket) do
    uuid = Exolyte.UserDB.create_user_link()
    host = ExolyteWeb.Endpoint.url()
    link = "#{host}/register/#{uuid}"
    
    qr_svg = 
      link
      |> EQRCode.encode()
      |> EQRCode.svg(width: 150)

    {:noreply, assign(socket, generated_link: link, generated_qr: qr_svg)}
  end

  def handle_event("create_channel", %{"channel_id" => channel_id, "channel_name" => channel_name}, socket) do
    user_id = socket.assigns.user_id
    if Regex.match?(~r/^[a-z][a-z0-9_]{4,30}[a-z0-9]$/, channel_id) do
      # check if exists
      case Exolyte.ChannelDB.get_channel(channel_id) do
        nil ->
          safe_name = String.slice(String.trim(channel_name), 0, 32)
          case Exolyte.ChannelDB.create_channel(channel_id, safe_name) do
            :ok ->
              Exolyte.ChannelDB.set_chop(channel_id, user_id)
              Exolyte.ChannelDB.add_user(channel_id, user_id)
              
              {:noreply, push_navigate(socket, to: "/channel/#{channel_id}")}
              
            {:error, _} ->
              {:noreply, assign(socket, channel_error: gettext("Failed to create channel."))}
          end
        _ ->
          {:noreply, assign(socket, channel_error: gettext("Channel already exists."))}
      end
    else
      {:noreply, assign(socket, channel_error: gettext("Invalid channel ID format."))}
    end
  end
  def handle_event("open_notifications", _, socket) do
    timestamp = System.os_time(:second)
    Exolyte.UserDB.update_user(socket.assigns.user_id, %{last_notification_read_at: timestamp})
    
    current_user = Map.put(socket.assigns.current_user, "last_notification_read_at", timestamp)
    
    {:noreply, assign(socket, unread_count: 0, last_notification_read_at: timestamp, current_user: current_user)}
  end

  def handle_event("clear_notifications", _, socket) do
    Exolyte.Notification.clear(socket.assigns.user_id)
    {:noreply, assign(socket, notifications: [], unread_count: 0)}
  end

  defp format_time(unix_ts) do
    unix_ts
    |> DateTime.from_unix!()
    |> Calendar.strftime("%x %H:%M")
  end
end
