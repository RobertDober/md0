defmodule Md0.ToyScanner do

  def scan_line(line), do: scan({:start, String.graphemes(line), 1, [], []})
  
  defp scan(scan_state)
  defp scan({ :start, [], col, partial, tokens }), do: emit_return(:blank, col, partial, tokens)
  defp scan({ :start, [" " | rest], col, partial, tokens }), do: scan({:indent, rest, col, [" "|partial], tokens})
  defp scan({ :start, [x   | rest], col, partial, tokens }), do: scan({:command, rest, col, [x], tokens})

  defp scan({ :indent, [], col, partial, tokens }), do: emit_return(:indent, col, partial, tokens)
  defp scan({ :indent, [" " | rest], col, partial, tokens }), do: scan({:indent, rest, col, [" " |partial], tokens})
  defp scan({ :indent, rest, col, partial, tokens }), do: emit({:any, rest, col, partial, tokens}, :indent)


  defp scan({ :command, [], col, partial, tokens }), do: emit_return(:command, col, partial, tokens)
  defp scan({ :command, [" " | _] = rest, col, partial, tokens }), do: emit({:ws, rest, col, partial, tokens}, :command)
  defp scan({ :command, [x|rest], col, partial, tokens }), do: scan({:command, rest, col, [x|partial], tokens})

  defp scan({ :ws, [], col, partial, tokens }), do: emit_return(:ws, col, partial, tokens)
  defp scan({ :ws, [" " | rest], col, partial, tokens }), do: scan({:ws, rest, col, [" "|partial], tokens})
  defp scan({ :ws, rest, col, partial, tokens }), do: emit({:any, rest, col, partial, tokens}, :ws)

  defp scan({ :any, [], col, partial, tokens }), do: emit_return(:any, col, partial, tokens)
  defp scan({ :any, [x|rest], col, partial, tokens }), do: scan({:any, rest, col, [x|partial], tokens})



  defp emit({ new_state, input, col, partial, tokens }, emit_state) do
    with rendered <- string_from(partial),
       do: scan({ new_state, input, col + String.length(rendered), [], [ {emit_state, rendered, col} | tokens] })
  end

  defp emit_return(state, col, partial, tokens), do: [{state, string_from(partial), col} | tokens] |> Enum.reverse

  defp string_from(partial), do: partial |> IO.iodata_to_binary() |> String.reverse()
end
