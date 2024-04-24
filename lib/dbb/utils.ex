defmodule Utils do
  @moduledoc """
  Utilities for the system
  """

  @spec title() :: String.t()
  def title() do
    Dbb.Schema.get_config()
    |> Map.get("ui_title", "dbb")
  end

  @spec schemas_menu_list() :: list(String.t())
  def schemas_menu_list() do
    Dbb.Schema.get_config()
    |> Map.get("schemas")
    |> Enum.map(&(%{
                    text: Map.get(&1, "name"),
                    url: "/#{Map.get(&1, "name")}"
                  }))
  end

  @spec capitalize_snake_case(atom() | String.t()) :: String.t()
  def capitalize_snake_case(data),
    do: data |> capitalize_tokens() |> Enum.join(" ")

  def modularize_snake_case(data),
      do: data |> capitalize_tokens() |> Enum.join("")

  defp capitalize_tokens(data) when is_atom(data),
      do: data |> to_string() |> capitalize_tokens()

  defp capitalize_tokens(data) when is_bitstring(data),
      do: data |> String.split("_") |> Enum.map(&String.capitalize/1)
end
