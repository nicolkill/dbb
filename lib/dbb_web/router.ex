defmodule DbbWeb.Router do
  use DbbWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {DbbWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers

    plug Guardian.Plug.Pipeline,
      module: Dbb.Accounts.Guardian,
      error_handler: Dbb.Accounts.AuthErrorHandler

    plug Guardian.Plug.VerifySession, claims: %{"typ" => "access"}
    plug Guardian.Plug.EnsureNotAuthenticated
  end

  pipeline :browser_auth do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {DbbWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers

    plug Guardian.Plug.Pipeline,
      module: Dbb.Accounts.Guardian,
      error_handler: Dbb.Accounts.AuthErrorHandler

    plug Guardian.Plug.VerifySession, claims: %{"typ" => "access"}
    plug Guardian.Plug.EnsureAuthenticated
    plug Guardian.Plug.LoadResource
  end

  pipeline :api do
    plug :accepts, ["json"]
    plug Dbb.Plugs.BasicApiAuth
  end

  scope "/", DbbWeb do
    pipe_through :browser

    live "/login", UserLive.Login, :index
    get "/login_save", AccountController, :login
  end

  scope "/admin", DbbWeb do
    pipe_through :browser_auth

    get "/logout", AccountController, :logout

    live_session :admin, on_mount: DbbWeb.LiveSession do
      live "/users", UserLive.Index, :index
      live "/users/new", UserLive.Index, :new
      live "/users/:id/edit", UserLive.Index, :edit
      live "/users/:id", UserLive.Show, :show
      live "/users/:id/show/edit", UserLive.Show, :edit

      live "/", Admin.AdminLive
      live "/:schema", AdminTable.AdminTableLive
      live "/:schema/create", AdminTable.AdminTableFormLive
      live "/:schema/update/:id", AdminTable.AdminTableFormLive
    end
  end

  #  todo: add docs to add the default admin, add permissions to the admin and hide buttons for those admins

  scope "/api/v1", DbbWeb do
    pipe_through :api

    get "/:schema", TableController, :index
    get "/:schema/:id", TableController, :show
    post "/:schema", TableController, :create
    put "/:schema/:id", TableController, :update
    delete "/:schema/:id", TableController, :delete
  end

  scope "/api_docs/v1" do
    forward "/", PhoenixSwagger.Plug.SwaggerUI, otp_app: :dbb, swagger_file: "swagger.json"
  end
end
