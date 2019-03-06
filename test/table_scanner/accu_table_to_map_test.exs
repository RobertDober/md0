defmodule TableScanner.AccuTableToMapTest do
  use ExUnit.Case

  import Md0.Scanner.TableScanner.Helper
  alias Md0.Scanner.TableScannerImpl, as: Scanner

  describe "Edge cases" do 
  test "empty" do
    assert accu_table_to_map([]) == %{}
  end
  test "one entry" do
    original = [
      {:state, " ", {:space, :return}}
    ]
    assert accu_table_to_map(original) == %{
      state: %{
        " " => {:space, nil, &Scanner.return/1} 
      }
    }
  end
  end

  describe "Acceptance" do
    test "..." do
      original = [
        {:start, " ", {:space, :return}},
        {:start, true, {:any, :emit_collect}},
        {:any, :eof, {:end, :any, :return}}
      ]
      assert accu_table_to_map(original) == %{
        start: %{ " " => {:space, nil, &Scanner.return/1},
          true => {:any, nil, &Scanner.emit_collect/1}},
         any: %{ eof: {:end, :any, &Scanner.return/1}}
       }
    end
  end


end
