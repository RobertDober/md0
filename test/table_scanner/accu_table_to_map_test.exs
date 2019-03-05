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
          " " => {:space, :space, &Scanner.return/1} 
        }
      }
    end
  end


end
