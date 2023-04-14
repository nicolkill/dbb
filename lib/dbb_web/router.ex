defmodule DbbWeb.Router do
  use DbbWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", DbbWeb do
    pipe_through :api
  end
end
