defmodule ExolyteWeb.Router do
  use ExolyteWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug ExolyteWeb.Plugs.SetLocale
    plug :fetch_live_flash
    plug :protect_from_forgery
    plug :put_root_layout, html: {ExolyteWeb.Layouts, :root}
    plug :put_secure_browser_headers
  end

  pipeline :unauthenticated do
    plug ExolyteWeb.Plugs.SetTheme
  end

  pipeline :authenticated do
    plug ExolyteWeb.Plugs.RequireAuth
  end

  pipeline :dev do
    nil
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :admin do
    plug ExolyteWeb.Plugs.Admin
  end

  scope "/", ExolyteWeb do
    pipe_through [:browser]

    get "/login", SessionController, :new
    post "/login", SessionController, :create
    get "/reset/:link_uuid", UserController, :show
    post "/reset/:link_uuid", UserController, :reset
    get "/not_found", ErrorController, :notfound
    get "/notification_sound.ogg", FileController, :bipo
    get "/notification_foreground_sound.ogg", FileController, :chi
    get "/sending_sound.ogg", FileController, :bipi
    get "/", PageController, :home
  end

  scope "/", ExolyteWeb do
    pipe_through [:browser, :authenticated]
  end

  scope "/admin", ExolyteWeb do
    pipe_through [:api, :admin]

    post "/channel/create", AdminController, :create_channel
    post "/channel/join", AdminController, :join
    post "/user/create", AdminController, :create_user
    post "/user/reset", AdminController, :reset_user

    # get "/test", InspectController, :show
  end

  live_session :default, on_mount: [ExolyteWeb.LiveAuth, ExolyteWeb.PutLocale] do
    scope "/", ExolyteWeb do
      pipe_through [:browser]

      live "/mypage", UserLive.Show
      live "/channel/:channel_id", ChannelLive
    end
  end

  # Other scopes may use custom stacks.
  scope "/api", ExolyteWeb do
    pipe_through [:api, :authenticated]

    # get "/log/:channel_id/:index", ExolyteWeb.ChannelLogController, :show
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  # if Application.compile_env(:exolyte, :dev_routes) do
  #   # If you want to use the LiveDashboard in production, you should put
  #   # it behind authentication and allow only admins to access it.
  #   # If your application does not have an admins-only section yet,
  #   # you can use Plug.BasicAuth to set up some basic authentication
  #   # as long as you are also using SSL (which you should anyway).
  #   import Phoenix.LiveDashboard.Router

  #   scope "/dev" do
  #     pipe_through [:browser, :dev]

  #     live_dashboard "/dashboard", metrics: ExolyteWeb.Telemetry
  #     forward "/mailbox", Plug.Swoosh.MailboxPreview
  #   end
  # end
end
