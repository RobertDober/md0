defmodule ToyTest do
  use ExUnit.Case
  

  alias Md0.ToyMacroScanner, as: S

  describe "single tokens" do
    test :empty do
      assert S.scan_line("") == [{:blank, "", 1}]
    end

    test :indent do
      assert S.scan_line("  ") == [{:indent, "  ", 1}]
    end

    test :command do
      assert S.scan_line("command") == [{:command, "command", 1}]
    end
  end

  describe "complex" do
    test "with indent" do
      assert S.scan_line("  hello world") == [
        {:indent, "  ", 1},
        {:any, "hello world", 3}
      ]
    end

    test "command" do
      assert S.scan_line("command arg") == [
        {:command, "command", 1},
        {:ws, " ", 8},
        {:any, "arg", 9}
      ]
    end
  end
end
