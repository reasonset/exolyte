defmodule ExolyteWeb.ConsoleLive do
  use ExolyteWeb, :live_view
  alias Exolyte.PublickeyAuth

  def mount(_params, _session, socket) do
    users = Exolyte.UserDB.list_users() |> Enum.map(fn {_key, user} -> user end) |> Enum.sort_by(& &1.id)

    {:ok, assign(socket, 
      auth_state: :pending, 
      public_key: nil, 
      active_tab: "dashboard",
      users: users,
      selected_user_id: nil,
      selected_user: nil,
      user_channels: [],
      generated_reset_link: nil,
      search_query: "",
      settings: Exolyte.Settings.get(),
      settings_saved: false
    )}
  end

  def render(assigns) do
    ~H"""
    <div id="admin-console" phx-hook="AdminAuth">
      <%= if @auth_state == :pending do %>
        <p>Authenticating...</p>
      <% end %>
      
      <%= if @auth_state == :unauthorized do %>
        <div class="card bg-base-200 shadow-xl max-w-3xl mx-auto mt-10">
          <div class="card-body">
            <h2 class="card-title text-error">
              <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" /></svg>
              Registration Required
            </h2>
            <p class="text-base-content">Please register your key to access the admin console.</p>
            
            <%= if @public_key do %>
              <div class="mt-4">
                <p class="font-bold mb-2 text-base-content">Run this command on the server:</p>
                <div class="mockup-code bg-base-300 text-base-content">
                  <pre data-prefix="$"><code>mix run scripts/api_cli.exs add_admin_key &lt;name&gt; <%= @public_key %></code></pre>
                </div>
              </div>
            <% end %>
          </div>
        </div>
      <% end %>

      <%= if @auth_state == :authenticated do %>
        <div class="drawer lg:drawer-open min-h-screen">
          <input id="admin-drawer" type="checkbox" class="drawer-toggle" />
          
          <div class="drawer-content flex flex-col bg-base-100">
            <!-- Navbar for mobile -->
            <div class="w-full navbar bg-base-300 lg:hidden">
              <div class="flex-none">
                <label for="admin-drawer" aria-label="open sidebar" class="btn btn-square btn-ghost">
                  <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" class="inline-block w-6 h-6 stroke-current"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 12h16M4 18h16"></path></svg>
                </label>
              </div>
              <div class="flex-1 px-2 mx-2 font-bold text-lg">Admin Console</div>
            </div>

            <!-- Page content -->
            <div class="p-6 flex-1">
              <div class="text-2xl font-bold mb-6 capitalize"><%= String.replace(@active_tab, "_", " ") %></div>
              
              <%= if @active_tab == "dashboard" do %>
                <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
                  <div class="stat shadow bg-base-200 rounded-box">
                    <div class="stat-title">Total Users</div>
                    <div class="stat-value">---</div>
                    <div class="stat-desc">Active accounts</div>
                  </div>
                  <div class="stat shadow bg-base-200 rounded-box">
                    <div class="stat-title">Channels</div>
                    <div class="stat-value">---</div>
                    <div class="stat-desc">Created channels</div>
                  </div>
                </div>
              <% end %>
              
              <%= if @active_tab == "users" do %>
                <div class="grid grid-cols-1 md:grid-cols-3 gap-6 h-[calc(100vh-12rem)]">
                  <!-- Left Sidebar: User List & Create Form -->
                  <div class="md:col-span-1 flex flex-col gap-4 overflow-hidden h-full">
                    <!-- Create User Form -->
                    <div class="card bg-base-200 shadow-sm shrink-0">
                      <div class="card-body p-4">
                        <h3 class="font-bold text-lg mb-2">Create User</h3>
                        <form phx-submit="create_user" class="flex flex-col gap-2">
                          <input type="text" name="user_id" placeholder="User ID (e.g. alice)" class="input input-sm input-bordered w-full" required />
                          <input type="text" name="display_name" placeholder="Display Name (Optional)" class="input input-sm input-bordered w-full" />
                          <input type="password" name="password" placeholder="Password" class="input input-sm input-bordered w-full" required />
                          <button type="submit" class="btn btn-sm btn-primary w-full mt-2">Create</button>
                        </form>
                      </div>
                    </div>

                    <!-- User List -->
                    <div class="card bg-base-200 shadow-sm flex-1 overflow-hidden flex flex-col">
                      <div class="p-4 font-bold border-b border-base-300">User List</div>
                      <div class="p-2 border-b border-base-300">
                        <form phx-change="search_users" onSubmit="return false;">
                          <input type="text" name="query" value={@search_query} phx-debounce="300" placeholder="Search by ID or name..." class="input input-sm input-bordered w-full" />
                        </form>
                      </div>
                      <ul class="menu flex-nowrap overflow-y-auto flex-1 p-2">
                        <%= for user <- Enum.filter(@users, fn u -> 
                              q = String.downcase(@search_query)
                              String.contains?(String.downcase(u.id), q) or 
                              String.contains?(String.downcase(Map.get(u, :display_name, "")), q)
                            end) do %>
                          <li>
                            <a class={if @selected_user_id == user.id, do: "active", else: ""} phx-click="select_user" phx-value-id={user.id}>
                              <div class="flex items-center gap-2">
                                <span class={if Map.get(user, :frozen, false), do: "badge badge-error badge-xs", else: "badge badge-success badge-xs"}></span>
                                <span class="font-medium"><%= user.id %></span>
                              </div>
                            </a>
                          </li>
                        <% end %>
                      </ul>
                    </div>
                  </div>

                  <!-- Right Side: User Details -->
                  <div class="md:col-span-2 overflow-y-auto">
                    <%= if @selected_user do %>
                      <div class="card bg-base-200 shadow-sm">
                        <div class="card-body">
                          <h2 class="card-title text-2xl mb-4 border-b border-base-300 pb-2">
                            User Details
                            <%= if Map.get(@selected_user, :frozen, false) do %>
                              <div class="badge badge-error ml-2">Invalid/Frozen</div>
                            <% else %>
                              <div class="badge badge-success ml-2">Active</div>
                            <% end %>
                          </h2>

                          <div class="grid grid-cols-1 md:grid-cols-2 gap-4 mb-6">
                            <div>
                              <p class="text-sm text-base-content/70">User ID</p>
                              <p class="font-bold text-lg"><%= @selected_user.id %></p>
                            </div>
                            <div>
                              <p class="text-sm text-base-content/70">Display Name</p>
                              <p class="font-bold text-lg"><%= @selected_user.display_name %></p>
                            </div>
                          </div>

                          <div class="flex gap-2 mb-6">
                            <button class={if Map.get(@selected_user, :frozen, false), do: "btn btn-success", else: "btn btn-error"} phx-click="toggle_freeze">
                              <%= if Map.get(@selected_user, :frozen, false), do: "Unfreeze Account", else: "Freeze Account" %>
                            </button>
                            
                            <button class="btn btn-outline" phx-click="generate_reset_link">
                              Generate Reset Link
                            </button>
                          </div>

                          <%= if @generated_reset_link do %>
                            <div class="alert alert-info shadow-sm mb-6">
                              <div>
                                <h3 class="font-bold">Password Reset Link Generated:</h3>
                                <div class="text-sm break-all font-mono mt-2 bg-base-100 p-2 rounded w-full">
                                  <%= @generated_reset_link %>
                                </div>
                              </div>
                            </div>
                          <% end %>

                          <h3 class="font-bold text-xl mb-4 border-b border-base-300 pb-2">Joined Channels</h3>
                          <%= if length(@user_channels) > 0 do %>
                            <div class="overflow-x-auto">
                              <table class="table w-full">
                                <thead>
                                  <tr>
                                    <th>Channel ID</th>
                                    <th>Name</th>
                                    <th>Actions</th>
                                  </tr>
                                </thead>
                                <tbody>
                                  <%= for channel <- @user_channels do %>
                                    <tr>
                                      <td><%= channel.id %></td>
                                      <td><%= channel.name %></td>
                                      <td>
                                        <button class="btn btn-xs btn-error" phx-click="remove_from_channel" phx-value-channel_id={channel.id}>Remove</button>
                                      </td>
                                    </tr>
                                  <% end %>
                                </tbody>
                              </table>
                            </div>
                          <% else %>
                            <p class="text-base-content/70 text-sm">This user is not a member of any channels.</p>
                          <% end %>

                        </div>
                      </div>
                    <% else %>
                      <div class="flex items-center justify-center h-full text-base-content/50">
                        <p>Select a user from the list to view details.</p>
                      </div>
                    <% end %>
                  </div>
                </div>
              <% end %>
              
              <%= if @active_tab == "channels" do %>
                <p>Channel management interface goes here.</p>
              <% end %>
              
              <%= if @active_tab == "invite" do %>
                <div class="card bg-base-200 shadow-xl max-w-xl mx-auto mt-10">
                  <div class="card-body items-center text-center">
                    <h2 class="card-title">Invite New User</h2>
                    <p class="mb-4 text-sm text-base-content/70">Generate a one-time link for a user to register their account. The link expires in 24 hours.</p>
                    
                    <button class="btn btn-primary" phx-click="generate_link">Generate Link</button>
                    
                    <%= if assigns[:generated_link] do %>
                      <div class="mt-6 w-full flex flex-col items-center gap-4">
                        <div class="bg-white p-4 rounded-xl shadow-sm inline-block">
                          <%= Phoenix.HTML.raw(@generated_qr) %>
                        </div>
                        <div class="form-control w-full">
                          <label class="label"><span class="label-text">Invitation URL</span></label>
                          <input type="text" value={@generated_link} class="input input-bordered w-full" readonly />
                        </div>
                      </div>
                    <% end %>
                  </div>
                </div>
              <% end %>
              
              <%= if @active_tab == "settings" do %>
                <div class="card bg-base-200 shadow-xl max-w-2xl mt-6">
                  <div class="card-body">
                    <h2 class="card-title mb-4">Instance Settings</h2>
                    
                    <%= if @settings_saved do %>
                      <div class="alert alert-success shadow-sm mb-4">
                        <svg xmlns="http://www.w3.org/2000/svg" class="stroke-current shrink-0 h-6 w-6" fill="none" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" /></svg>
                        <span>Settings saved successfully.</span>
                      </div>
                    <% end %>

                    <form phx-submit="save_settings" class="flex flex-col gap-6">
                      <!-- Instance Name -->
                      <div class="form-control w-full">
                        <label class="label">
                          <span class="label-text font-bold">Instance Name</span>
                        </label>
                        <input type="text" name="instance_name" value={Map.get(@settings, "instance_name", "")} class="input input-bordered w-full" required />
                      </div>

                      <!-- Allow User Invites -->
                      <div class="form-control">
                        <label class="label cursor-pointer justify-start gap-4">
                          <input type="checkbox" name="allow_user_invites" value="true" checked={Map.get(@settings, "allow_user_invites", false)} class="toggle toggle-primary" />
                          <span class="label-text font-bold">Allow Users to Invite Others</span>
                        </label>
                        <p class="text-sm text-base-content/70 mt-1 ml-16">If enabled, regular users can generate invitation links.</p>
                      </div>

                      <!-- Allow Channel Creation -->
                      <div class="form-control">
                        <label class="label cursor-pointer justify-start gap-4">
                          <input type="checkbox" name="allow_channel_creation" value="true" checked={Map.get(@settings, "allow_channel_creation", false)} class="toggle toggle-primary" />
                          <span class="label-text font-bold">Allow Users to Create Channels</span>
                        </label>
                        <p class="text-sm text-base-content/70 mt-1 ml-16">If enabled, regular users can create new channels.</p>
                      </div>

                      <div class="card-actions justify-end mt-4">
                        <button type="submit" class="btn btn-primary">Save Settings</button>
                      </div>
                    </form>
                  </div>
                </div>
              <% end %>
            </div>
          </div> 
          
          <!-- Sidebar -->
          <div class="drawer-side z-50">
            <label for="admin-drawer" aria-label="close sidebar" class="drawer-overlay"></label> 
            <ul class="menu p-4 w-72 min-h-full bg-base-200 text-base-content flex-nowrap overflow-y-auto">
              <li class="mb-4 font-bold text-xl px-4 py-2 hidden lg:block">Exolyte Admin</li>
              
              <li class="menu-title">Main</li>
              <li><a class={if @active_tab == "dashboard", do: "active", else: ""} phx-click="change_tab" phx-value-tab="dashboard">Dashboard</a></li>
              
              <li class="menu-title mt-4">Management</li>
              <li><a class={if @active_tab == "users", do: "active", else: ""} phx-click="change_tab" phx-value-tab="users">Users</a></li>
              <li><a class={if @active_tab == "channels", do: "active", else: ""} phx-click="change_tab" phx-value-tab="channels">Channels</a></li>
              
              <li class="menu-title mt-4">System</li>
              <li><a class={if @active_tab == "settings", do: "active", else: ""} phx-click="change_tab" phx-value-tab="settings">Settings</a></li>
              <li><a class={if @active_tab == "invite", do: "active", else: ""} phx-click="change_tab" phx-value-tab="invite">Invite User</a></li>
            </ul>
          </div>
        </div>
      <% end %>
    </div>
    """
  end

  def handle_event("change_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, active_tab: tab, generated_link: nil, generated_qr: nil, search_query: "", settings_saved: false)}
  end

  def handle_event("save_settings", params, socket) do
    # When checkboxes are unchecked, they don't send any value. We must explicitly set them to false if missing.
    settings_to_save = %{
      "instance_name" => Map.get(params, "instance_name", ""),
      "allow_user_invites" => Map.get(params, "allow_user_invites", "false") == "true",
      "allow_channel_creation" => Map.get(params, "allow_channel_creation", "false") == "true"
    }
    
    updated_settings = Exolyte.Settings.update(settings_to_save)
    
    {:noreply, assign(socket, settings: updated_settings, settings_saved: true)}
  end

  def handle_event("search_users", %{"query" => query}, socket) do
    {:noreply, assign(socket, search_query: query)}
  end

  def handle_event("generate_link", _params, socket) do
    uuid = Exolyte.UserDB.create_user_link()
    host = ExolyteWeb.Endpoint.url()
    link = "#{host}/register/#{uuid}"
    
    qr_svg = 
      link
      |> EQRCode.encode()
      |> EQRCode.svg(width: 250)

    {:noreply, assign(socket, generated_link: link, generated_qr: qr_svg)}
  end

  def handle_event("select_user", %{"id" => id}, socket) do
    user = Exolyte.UserDB.get_user(id)
    channels = Exolyte.ChannelDB.channels_for_user(id)
    
    {:noreply, assign(socket, 
      selected_user_id: id,
      selected_user: user,
      user_channels: channels,
      generated_reset_link: nil
    )}
  end

  def handle_event("create_user", %{"user_id" => user_id, "display_name" => display_name, "password" => password}, socket) do
    display_name = if String.trim(display_name) == "", do: user_id, else: display_name
    Exolyte.UserDB.put_user(user_id, display_name, password)
    
    users = Exolyte.UserDB.list_users() |> Enum.map(fn {_key, user} -> user end) |> Enum.sort_by(& &1.id)
    {:noreply, assign(socket, users: users)}
  end

  def handle_event("toggle_freeze", _params, socket) do
    user_id = socket.assigns.selected_user_id
    if user_id do
      user = Exolyte.UserDB.get_user(user_id)
      frozen = Map.get(user, :frozen, false)
      Exolyte.UserDB.update_user(user_id, %{frozen: !frozen})
      
      # Refresh data
      updated_user = Exolyte.UserDB.get_user(user_id)
      users = Exolyte.UserDB.list_users() |> Enum.map(fn {_key, u} -> u end) |> Enum.sort_by(& &1.id)
      
      {:noreply, assign(socket, selected_user: updated_user, users: users)}
    else
      {:noreply, socket}
    end
  end

  def handle_event("generate_reset_link", _params, socket) do
    user_id = socket.assigns.selected_user_id
    if user_id do
      uuid = Exolyte.UserDB.create_reset_link(user_id)
      host = ExolyteWeb.Endpoint.url()
      link = "#{host}/reset/#{uuid}"
      {:noreply, assign(socket, generated_reset_link: link)}
    else
      {:noreply, socket}
    end
  end

  def handle_event("remove_from_channel", %{"channel_id" => channel_id}, socket) do
    user_id = socket.assigns.selected_user_id
    if user_id do
      Exolyte.ChannelDB.remove_user(channel_id, user_id)
      channels = Exolyte.ChannelDB.channels_for_user(user_id)
      {:noreply, assign(socket, user_channels: channels)}
    else
      {:noreply, socket}
    end
  end

  def handle_event("request_challenge", _params, socket) do
    {:ok, cuuid, cvalue} = PublickeyAuth.create_challenge()
    {:noreply, push_event(socket, "challenge", %{challenge_id: cuuid, secret: cvalue})}
  end

  def handle_event("verify_challenge", %{"signature" => signature, "challenge_id" => challenge_id, "public_key" => public_key}, socket) do
    if PublickeyAuth.verify(public_key, signature, challenge_id) do
      db = Exolyte.DB.get_db()
      case CubDB.get(db, {:adminkey, public_key}) do
        nil ->
          {:noreply, assign(socket, auth_state: :unauthorized, public_key: public_key)}
        _name ->
          {:noreply, assign(socket, auth_state: :authenticated)}
      end
    else
      {:noreply, assign(socket, auth_state: :unauthorized, public_key: public_key)}
    end
  end
end