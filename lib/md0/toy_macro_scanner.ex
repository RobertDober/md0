defmodule Md0.ToyMacroScanner do

  use Md0.Scanner.ManualMacro

  
  state :start do
    empty emit: :blank
    on " ", :indent
    anything :command
  end

  state :any do
    # Should next transition be default?
    empty emit: :any
    anything :any
  end

  state :indent do
    empty emit: :indent
    on " ", :indent
    anything :any, emit: :indent
  end

  state :command do
    empty emit: :command
    on " ", :ws, emit: :command
    anything :command
  end

  state :ws do
    empty emit: :ws
    on " ", :ws
    anything :any, emit: :ws
  end


  # state :indent do
  #   empty :indent
  #   # defp scan({ :indent, [], col, partial, tokens }), do: emit_return(:indent, col, partial, tokens)
  #   on " ", :collect
  #   # defp scan({ :indent, [" " | rest], col, partial, tokens }), do: scan({:indent, rest, col, [" " |partial], tokens})
  #   anything state: :any, emit: :indent
  #   # defp scan({ :indent, rest, col, partial, tokens }), do: emit({:any, rest, col, partial, tokens}, :indent)
  # end

  # state :command do
  #   empty :command
  #   # defp scan({ :command, [], col, partial, tokens }), do: emit_return(:command, col, partial, tokens)
  #   on " ", emit: :command, pushback: true, state: :ws
  # # defp scan({ :command, [" " | _] = rest, col, partial, tokens }), do: emit({:ws, rest, col, partial, tokens}, :command)
  #   on " ", emit: :command, state: :ws
  # #defp scan({ :command, [" " | rest], col, _partial, tokens }), do: emit({:ws, rest, col, [" "], tokens}, :command)
  #   anything :collect
  # # defp scan({ :command, [x|rest], col, partial, tokens }), do: scan({:command, rest, col, [x|partial], tokens})
  # end

  # state :ws do
  #   empty :ws
  # # defp scan({ :ws, [], col, partial, tokens }), do: emit_return(:ws, col, partial, tokens)
  #   on " ", :collect 
  # # defp scan({ :ws, [" " | rest], col, partial, tokens }), do: scan({:ws, rest, col, [" "|partial], tokens})
  #   anything state: :any, emit: :ws
  # # defp scan({ :ws, rest, col, partial, tokens }), do: emit({:any, rest, col, partial, tokens}, :ws)
  # end

  # state :any do
  #   empty :any
  # # defp scan({ :any, [], col, partial, tokens }), do: emit_return(:any, col, partial, tokens)
  #   anything :collect
  # # defp scan({ :any, [x|rest], col, partial, tokens }), do: scan({:any, rest, col, [x|partial], tokens})
  # end



  # defp emit({ new_state, input, col, partial, tokens }, emit_state) do
  #   with rendered <- string_from(partial),
  #      do: scan({ new_state, input, col + String.length(rendered), [], [ {emit_state, rendered, col} | tokens] })
  # end

end
