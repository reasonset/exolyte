defmodule ExolyteWeb.UserLive.Show do
  use ExolyteWeb, :live_view

  @themes MapSet.new(["kawaiifb", "synthwave", "coffee", "winter", "dark", "light"])

  def mount(_params, session, socket) do
    user_id = session["user_id"]
    channels = Exolyte.ChannelDB.channels_for_user(user_id)

    {:ok,
     socket
     |> assign(:user_id, user_id)
     |> assign(:channels, channels)}
  end

  def render(assigns) do
    ~H"""
    <div class="max-w-xl mx-auto mt-10">
      <div class="card bg-base-100 shadow-xl">
        <div class="card-body">
          <h2 class="card-title text-2xl" style={"color: #{@current_user.user_color};"}><%= @current_user.display_name %></h2>

          <div class="mt-4">
            <p><span class="font-bold"><%= gettext("User ID") %>: </span><code><%= @user_id %></code></p>
          </div>

          <div class="mt-6">
            <h3 class="text-lg font-semibold mb-2"><%= gettext("Channels") %></h3>
            <ul class="menu bg-base-200 rounded-box">
              <%= for channel <- @channels do %>
                  <li><a href={"/channel/#{channel.id}"} phx-link="navigate"><%= channel.name %></a></li>
              <% end %>
            </ul>
          </div>
        </div>
      </div>
      <fieldset class="fieldset bg-base-200 border-base-300 rounded-box w-xs border p-4">
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
      </fieldset>
    </div>
    """
  end

  def handle_event("update_user", %{"disp_name" => display_name, "theme_name" => user_theme}, socket) do
    theme = if MapSet.member?(@themes, user_theme), do: user_theme, else: "kawaiifb"

    newsetting = %{display_name: display_name, theme: theme}
    Exolyte.UserDB.update_user(socket.assigns.user_id, newsetting)

    current_user = Map.merge(socket.assigns.current_user, newsetting)

    {:noreply, socket
     |> assign(:current_user, current_user)
     |> assign(:user_theme, theme)}
  end
end
