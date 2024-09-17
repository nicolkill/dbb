defmodule Dbb.Utils do
  @moduledoc """
  Utilities for the system
  """

  @nums "0123456789"
  @symbols "!@#$%^*()[]|'+{}"
  @letters "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
  @chars "#{@letters}#{@nums}"

  @spec gen_str_letters(number()) :: String.t()
  def gen_str_letters(length), do: generate(@letters, length)

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
        url: "/admin/#{Map.get(&1, "name")}"
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

  def purify_params(params) when is_map(params) and not is_struct(params) do
    params
    |> Map.to_list()
    |> Enum.reduce(%{}, fn {key, value}, acc ->
      Map.put(acc, to_string(key), purify_params(value))
    end)
  end

  def purify_params(params), do: params

  def validate_email(email) when is_binary(email) do
    Regex.match?(~r/(\w+)@([\w.]+)/, email)
  end
end
