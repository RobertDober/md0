defmodule HsTest do
  use ExUnit.Case
  alias Support.LongerScanner, as: S

  test "h1" do
    assert S.scan_document("#") == [{:h1, "#", 1, 1}]
  end

  test "h2" do
    assert S.scan_document("##") == [{:h2, "##", 1, 1}]
  end

  test "h3" do
    assert S.scan_document("###") == [{:else, "###", 1, 1}]
  end

  test "ab" do
    assert S.scan_document("ab") == [{:ab, "ab", 1, 1}]
  end

  test "prefix" do
    assert S.scan_document("$>c") == [{:prefix, "$>", 1, 1}, {:prefixed, "c", 1, 3}]
  end
end
