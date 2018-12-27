defmodule Md0Test do
  use ExUnit.Case
  @input """
  Hello *World*
    * Fint`Item``
      Indent ``Grüße
    x  * y
  """

  @tokens [
    {:any, "Hello", 1, 1}, {:ws, " ", 1, 6}, {:star, "*", 1, 7}, {:any, "World", 1, 8}, {:star, "*", 1, 13},
    {:li, "  * ", 2, 1}, {:any, "Fint", 2, 5}, {:back, "`", 2, 9}, {:any, "Item", 2, 10}, {:back, "``", 2, 14},
    {:indent, "    ", 3, 1}, {:any, "Indent", 3, 5}, {:ws, " ", 3, 11}, {:back, "``", 3, 12}, {:any, "Grüße", 3, 14},
    {:indent, "  ", 4, 1}, {:any, "x", 4, 3}, {:ws, "  ", 4, 4}, {:star, "*", 4, 6}, {:ws, " ", 4, 7}, {:any, "y", 4, 8}
  ]

  describe "Regex Scanner" do
    test "sample" do
      assert Md0.RgxScanner.scan_document(@input) == @tokens
    end
  end

  # describe "Manual Scanner" do
  #   test "sample" do
  #     assert Md0.ManualScanner.scan(@input) == @tokens
  #   end
  # end

  # describe "Macro Scanner" do
  #   test "sample" do
  #     assert Md0.MacroScanner.scan(@input) == @tokens
  #   end
  # end
end
