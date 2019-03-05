defmodule AccuTest do
  use ExUnit.Case
  
  alias Support.AccuTester

  test "accu" do
    assert [] == AccuTester.show_accu
  end
end
