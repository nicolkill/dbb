defmodule DbbWeb.Router do
  use DbbWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {DbbWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
    plug Dbb.Plugs.Auth
  end

  scope "/", DbbWeb do
    pipe_through :browser

#    get "/", Page.PageController, :home
    live "/", Admin.AdminLive
    live "/:schema", AdminTable.AdminTableLive
    live "/:schema/create", AdminTable.AdminTableFormLive
    live "/:schema/update/:id", AdminTable.AdminTableFormLive
  end

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
