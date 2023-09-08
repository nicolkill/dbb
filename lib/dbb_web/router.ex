defmodule DbbWeb.Router do
  use DbbWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
    plug Dbb.Plugs.Auth
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
