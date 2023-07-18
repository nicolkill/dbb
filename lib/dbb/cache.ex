defmodule Dbb.Cache do
  @cache_table :cache_table_ulist

  def init() do
    if :ets.whereis(@cache_table) == :undefined do
      :ets.new(@cache_table, [:set, :public, :named_table])
    end

    :ok
  end

  def save_data(key, data) do
    :ets.insert(@cache_table, {key, data})
  end

  def get_data(key, opt \\ :get) do
    case :ets.lookup(@cache_table, key) do
      [{^key, data}] ->
        if opt == :pop do
          delete(key)
        end

        {:ok, data}

      _ ->
        {:error, :not_found}
    end
  end

  def delete(key) do
    :ets.delete(@cache_table, key)
  end

  def match_delete(key) do
    pattern = {[key, :"$1"], :"$2"}
    :ets.match_delete(@cache_table, pattern)
  end

  def match(key, opt \\ :get) do
    pattern = {[key, :"$1"], :"$2"}

    case :ets.match(@cache_table, pattern) do
      [] ->
        {:error, :not_found}

      data ->
        if opt == :pop do
          match_delete(key)
        end

        Enum.map(data, &{Enum.at(&1, 0), Enum.at(&1, 1)})
    end
  end

  def clean() do
    :ets.delete_all_objects(@cache_table)
  end
end
