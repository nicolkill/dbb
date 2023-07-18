defmodule Dbb.ConfigTest do
  use Dbb.DataCase

  alias Dbb.Schema

  describe "config tests suite" do
    test "Dbb.Schema.load_config/0 returns the config in json" do
      Schema.load_config()
      assert %{} = Schema.get_config()
    end
  end
end
