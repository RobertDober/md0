defmodule Tools.PutDeepTest do
  use ExUnit.Case
  
  alias Md0.Tools.Map, as: M

  describe "No errors" do
    test "insert one level into empty" do
      assert M.put_deep(%{}, [:alpha], "a") == {:ok, %{alpha: "a"}}
    end

    test "insert two levels into empty" do
      assert M.put_deep(%{}, [:alpha, :beta], "ab") == {:ok, %{alpha: %{beta: "ab"}}}
    end

    test "insert two levels into existing" do
      assert M.put_deep(%{alpha: %{gamma: "ag"}}, [:alpha, :beta], "ab") == {:ok, %{alpha: %{beta: "ab", gamma: "ag"}}}
    end
  end

  describe "Error cases" do
    test "not a map" do
      assert M.put_deep(42, [:alpha], "a") == {:error, "not a map 42"}
    end

    test "not a map element" do
      assert M.put_deep(%{alpha: 42}, [:alpha, :beta], "a") == {:error, "not a map 42"}
    end

    test "cannot override" do
      assert M.put_deep(%{alpha: %{beta: %{}}}, [:alpha, :beta], "a") == {:error, "cannot override beta inside %{beta: %{}}"}
    end
  end
end
