defmodule Dbb.Accounts.TrollBridge do
  @behaviour TrollBridge.Behaviour

  alias Dbb.Schema
  alias Dbb.Accounts.Guardian

  @impl TrollBridge.Behaviour
  def actions do
    ["all", "index", "create", "update", "delete"]
  end

  @impl TrollBridge.Behaviour
  def scopes do
    Schema.schema_roles()
    |> IO.inspect(label: "@@@@@@@@@ scopes")

    ["admin", "user"]
  end

  @impl TrollBridge.Behaviour
  def user_roles(conn_or_socket) do
    Guardian.Plug.current_resource(conn_or_socket)
    |> IO.inspect(label: "@@@@@@@@@ current_resource")

    ["admin", "user"]
  end

  @impl TrollBridge.Behaviour
  def user_permissions(conn_or_socket) do
    Guardian.Plug.current_resource(conn_or_socket)
    |> IO.inspect(label: "@@@@@@@@@ Plug.current_resource")

    Schema.schema_roles()
    |> IO.inspect(label: "@@@@@@@@@ user_permissions")
  end

  def roles_to_permissions(roles) do
    Enum.reduce(roles, %{}, fn
      "all", acc ->
        Map.put(acc, "admin", ["all"])

      role, acc ->
        [scope, permission] = String.split(role, ".")
        permissions =  Map.get(acc, scope, [])
        Map.put(acc, scope, permissions ++ [permission])
    end)
  end
end