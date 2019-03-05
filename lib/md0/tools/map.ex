defmodule Md0.Tools.Map do
  
  def put_deep(map, keys, value)
  def put_deep(not_a_map, _keys, _value) when not is_map(not_a_map) do
    {:error, "not a map #{inspect not_a_map}"}
  end
  def put_deep(map, [k], value) do
    if Map.has_key?(map, k) do
      {:error, "cannot override #{k} inside #{inspect map}"}
    else
      {:ok, Map.put(map, k, value)}
    end
  end
  def put_deep(map, [k|ks], value) do
    with {:ok, inner} <- put_deep(Map.get(map, k, %{}), ks, value), do:
      {:ok, Map.put(map, k, inner)}
  end


end
