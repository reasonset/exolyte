defmodule ExolyteWeb.Router do
  use ExolyteWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug ExolyteWeb.Plugs.SetLocale
    plug :fetch_live_flash
    plug :put_root_layout, html: {ExolyteWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
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

  scope "/", ExolyteWeb do
    pipe_through [:browser]

    get "/login", SessionController, :new
    post "/login", SessionController, :create
    get "/reset/:link_uuid", UserController, :show
    post "/reset/:link_uuid", UserController, :reset
  end

  scope "/", ExolyteWeb do
    pipe_through [:browser, :authenticated]

    get "/", PageController, :home
  end

  live_session :default, on_mount: ExolyteWeb.LiveAuth do
    pipe_through [:browser]

    live "/mypage", ExolyteWeb.UserLive.Show
  end

  # Other scopes may use custom stacks.
  scope "/api", ExolyteWeb do
    pipe_through :api
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
