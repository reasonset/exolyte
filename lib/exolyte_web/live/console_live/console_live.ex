defmodule ExolyteWeb.ConsoleLive do
  use ExolyteWeb, :live_view
  alias Exolyte.PublickeyAuth

  def mount(_params, _session, socket) do
    {:ok, assign(socket, auth_state: :pending, public_key: nil)}
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
        <div>
          <h2>Admin Console</h2>
          <p>Welcome to the admin console.</p>
        </div>
      <% end %>
    </div>
    """
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