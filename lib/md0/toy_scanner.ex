defmodule Md0.ToyScanner do

  def scan_line(line), do: scan({:start, String.graphemes(line), 1, [], []})
  
  # Head is generated
  defp scan(scan_state)
  # state :start do
  #   empty :blank | nil would not add token
  defp scan({ :start, [], col, partial, tokens }), do: emit_return(:blank, col, partial, tokens)
  #   on " ", state: :indent
  defp scan({ :start, [" " | rest], col, partial, tokens }), do: scan({:indent, rest, col, [" "|partial], tokens})
  #   anything state: :command
  defp scan({ :start, rest, col, _partial, tokens }), do: scan({:command, rest, col, [], tokens})
  # defp scan({ :start, [x   | rest], col, partial, tokens }), do: scan({:command, rest, col, [x], tokens})
  # end

  # state :indent do
  #  empty :indent
  defp scan({ :indent, [], col, partial, tokens }), do: emit_return(:indent, col, partial, tokens)
  #  on " ", :collect
  defp scan({ :indent, [" " | rest], col, partial, tokens }), do: scan({:indent, rest, col, [" " |partial], tokens})
  #  anything state: :any, emit: :indent
  defp scan({ :indent, rest, col, partial, tokens }), do: emit({:any, rest, col, partial, tokens}, :indent)
  # end

  # state :command do
  #  empty :command
  defp scan({ :command, [], col, partial, tokens }), do: emit_return(:command, col, partial, tokens)
  #  on: " ", emit: :command, pushback: true, state: :ws
  defp scan({ :command, [" " | _] = rest, col, partial, tokens }), do: emit({:ws, rest, col, partial, tokens}, :command)
  #  on: " ", emit: :command, state: :ws
  #defp scan({ :command, [" " | rest], col, _partial, tokens }), do: emit({:ws, rest, col, [" "], tokens}, :command)
  #  anything :collect
  defp scan({ :command, [x|rest], col, partial, tokens }), do: scan({:command, rest, col, [x|partial], tokens})
  # end

  # state :ws do
  #   empty :ws
  defp scan({ :ws, [], col, partial, tokens }), do: emit_return(:ws, col, partial, tokens)
  #   on " ", :collect 
  defp scan({ :ws, [" " | rest], col, partial, tokens }), do: scan({:ws, rest, col, [" "|partial], tokens})
  #   anything state: :any, emit: :ws
  defp scan({ :ws, rest, col, partial, tokens }), do: emit({:any, rest, col, partial, tokens}, :ws)
  # end

  # state :any do
  #   empty :any
  defp scan({ :any, [], col, partial, tokens }), do: emit_return(:any, col, partial, tokens)
  #   anything :collect
  defp scan({ :any, [x|rest], col, partial, tokens }), do: scan({:any, rest, col, [x|partial], tokens})
  # end



  defp emit({ new_state, input, col, partial, tokens }, emit_state) do
    with rendered <- string_from(partial),
       do: scan({ new_state, input, col + String.length(rendered), [], [ {emit_state, rendered, col} | tokens] })
  end

  defp emit_return(state, col, partial, tokens), do: [{state, string_from(partial), col} | tokens] |> Enum.reverse

  defp string_from(partial), do: partial |> IO.iodata_to_binary() |> String.reverse()
end
