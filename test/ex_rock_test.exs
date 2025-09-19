defmodule ExRocketTest do
  use ExRocket.Case, async: false
  doctest ExRocket

  describe "common" do
    test "check lxcode/0 returns" do
      assert ExRocket.lxcode() == {:ok, :vsn1}
    end
  end

  describe "app" do
    test "correct loading" do
      Application.stop(@app)
      Application.unload(@app)
      assert :ok == Application.load(@app)
    end
  end
end
