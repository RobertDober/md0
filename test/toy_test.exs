defmodule ToyTest do
  use ExUnit.Case
  

  alias Md0.ToyMacroScanner, as: S

  describe "single tokens" do
    test :empty do
      assert S.scan_line({"", 1}) == [{:blank, "", 1, 1}]
    end

    test :indent do
      assert S.scan_line({"  ", 1}) == [{:indent, "  ", 1, 1}]
    end

    test :command do
      assert S.scan_line({"command", 1}) == [{:command, "command", 1, 1}]
    end
  end

  describe "complex" do
    test "with indent" do
      assert S.scan_line({"  hello world", 1}) == [
        {:indent, "  ", 1, 1},
        {:any, "hello world", 1, 3}
      ]
    end

    test "command" do
      assert S.scan_line({"command arg", 1}) == [
        {:command, "command", 1, 1},
        {:ws, " ", 1, 8},
        {:any, "arg", 1, 9}
      ]
    end
  end
end
