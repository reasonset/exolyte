defmodule ExolyteWeb.UserLive.Show do
  use ExolyteWeb, :live_view

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
    </div>
    """
  end
end
