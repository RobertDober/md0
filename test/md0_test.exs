defmodule Md0Test do
  use ExUnit.Case
  @input """
  Hello *World*
    * Fint`Item``
      Indent ``Grüße

    x  * y
    
    * 
    **
  """

  @tokens [
    {:any, "Hello", 1, 1}, {:ws, " ", 1, 6}, {:star, "*", 1, 7}, {:any, "World", 1, 8}, {:star, "*", 1, 13},
    {:indent, "  ", 2, 1}, {:li, "* ", 2, 3}, {:any, "Fint", 2, 5}, {:back, "`", 2, 9}, {:any, "Item", 2, 10}, {:back, "``", 2, 14},
    {:indent, "    ", 3, 1}, {:any, "Indent", 3, 5}, {:ws, " ", 3, 11}, {:back, "``", 3, 12}, {:any, "Grüße", 3, 14},
    {:indent, "  ", 5, 1}, {:any, "x", 5, 3}, {:ws, "  ", 5, 4}, {:li, "* ", 5, 6}, {:any, "y", 5, 8},
    {:indent, "  ", 6, 1},
    {:indent, "  ", 7, 1}, {:li, "* ", 7, 3},
    {:indent, "  ", 8, 1}, {:star, "**", 8, 3},
  ]

  describe "Regex Scanner" do
    test "sample" do
      assert Md0.RgxScanner.scan_document(@input) == @tokens
    end
    test "edge case empty" do
      assert Md0.RgxScanner.scan_document("") == []
    end
  end

  describe "Manual Scanner" do
    test "sample" do
      assert Md0.ManualScanner.scan_document(@input) == @tokens
    end
    test "edge case empty" do
      assert Md0.ManualScanner.scan_document("") == []
    end
  end

  describe "Table Scanner" do
    test "sample" do
      assert Md0.TableScanner.scan_document(@input) == @tokens
    end
    test "edge case empty" do
      assert Md0.TableScanner.scan_document("") == []
    end
    @debugging """
      ``Hello
    * *
    *`
    * 
    """
    test "debugging" do
      assert Md0.TableScanner.scan_document(@debugging) == [
        {:indent, "  ", 1, 1}, {:back, "``", 1, 3}, {:any, "Hello", 1, 5},
        {:li, "* ", 2, 1}, {:star, "*", 2, 3},
        {:star, "*", 3, 1}, {:back, "`", 3, 2},
        {:li, "* ", 4, 1},
      ]
    end
  end

  describe "Macro Scanner" do
    test "sample" do
      assert Md0.MacroScanner.scan(@input) == @tokens
    end
    test "edge case empty" do
      assert Md0.MacroScanner.scan_document("") == []
    end
  end

end
