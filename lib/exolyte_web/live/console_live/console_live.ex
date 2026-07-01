defmodule ExolyteWeb.ConsoleLive do
  use ExolyteWeb, :live_view
  alias Exolyte.PublickeyAuth

  def mount(_params, _session, socket) do
    {:ok, assign(socket, auth_state: :pending, public_key: nil, active_tab: "dashboard")}
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
                <p>User management interface goes here.</p>
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
                <p>System settings go here.</p>
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
    {:noreply, assign(socket, active_tab: tab, generated_link: nil, generated_qr: nil)}
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