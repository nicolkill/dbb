defmodule Dbb.Utils do
  @moduledoc """
  Utilities for the system
  """

  @nums "0123456789"
  @symbols "!@#$%^*()[]|'+{}"
  @chars "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
  @any "#{@nums}#{@chars}#{@symbols}"

  @spec gen_str(number()) :: String.t()
  def gen_str(length), do: generate(@chars, length)

  @spec gen_sym(number()) :: String.t()
  def gen_sym(length), do: generate(@symbols, length)

  @spec gen_num(number()) :: String.t()
  def gen_num(length), do: generate(@nums, length)

  @spec gen_str_num(number()) :: String.t()
  def gen_str_num(length), do: generate("#{@nums}#{@chars}", length)

  @spec gen_any(number()) :: String.t()
  def gen_any(length), do: generate("#{@nums}#{@chars}#{@symbols}", length)

  defp generate(list, length) do
    list
    |> String.codepoints()
    |> Enum.take_random(length)
    |> Enum.join("")
  end

  @spec title() :: String.t()
  def title() do
    Dbb.Schema.get_config()
    |> Map.get("ui", %{})
    |> Map.get("title", "dbb")
  end

  @spec schemas_menu_list() :: list(String.t())
  def schemas_menu_list() do
    Dbb.Schema.get_config()
    |> Map.get("schemas")
    |> Enum.map(
      &%{
        text: Map.get(&1, "name"),
        url: "/#{Map.get(&1, "name")}"
      }
    )
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
