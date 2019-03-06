defmodule Md0.MacroScanner do

  use Md0.Scanner.TableScanner

  # @typep token :: {atom(), String.t, number()}
  # @typep tokens :: list(token)
  # @typep graphemes :: list(String.t)
  # @typep scan_info :: {atom(), graphemes(), number(), IO.chardata(), tokens()}


  state :any do
    #           input, {next_state, emit_state(1), action}    (1) if different from current state
    deftransition " ", {:ws, :emit_collect}
    deftransition "*", {:li, :emit_collect}
    deftransition "`", {:back, :emit_collect}
    deftransition true, {:any, :collect}
    deftransition :eof, {:any, :emit_return}
  end

  state :back do
    deftransition " ", {:ws, :emit_collect}
    deftransition "*", {:li, :emit_collect}
    deftransition "`", {:back, :collect}
    deftransition true, {:any, :emit_collect}
    deftransition :eof, {:back, :emit_return}
  end

  state :indent do
    deftransition " ", {:indent, :collect}
    deftransition "*", {:li, :emit_collect}
    deftransition "`", {:back, :emit_collect}
    deftransition true, {:any, :emit_collect}
    deftransition :eof, {:indent, :emit_return}
  end

  state :li do
    deftransition " ", {:rest, :collect_emit}
    deftransition "*", {:star, :collect}
    deftransition "`", {:back, :star, :emit_collect}
    deftransition true, {:any, :star, :emit_collect}
    deftransition :eof, {:any, :star, :emit_return}
  end

  state :rest do
    deftransition  " ", {:ws, :collect}
    deftransition  "*", {:li, :collect}
    deftransition  "`", {:back, :collect}
    deftransition  true, {:any, :collect}
    deftransition  :eof, {nil, :return}
  end

  state :star do
    deftransition  " ", {:ws, :emit_collect}
    deftransition  "*", {:star, :collect}
    deftransition  "`", {:back, :emit_collect}
    deftransition  true, {:any, :emit_collect}
    deftransition  :eof, {:star, :emit_return}
  end

  state :start do
    deftransition  " ", {:indent, :collect}
    deftransition  "*", {:li, :collect}
    deftransition  "`", {:back, :collect}
    deftransition  true, {:any, :collect}
    deftransition  :eof, {nil, :return}
  end

  state :ws do
    deftransition  " ", {:ws, :collect}
    deftransition  "*", {:li, :emit_collect}
    deftransition  "`", {:back, :emit_collect}
    deftransition  true, {:any, :emit_collect}
    deftransition  :eof, {:ws, :emit_return}
  end

end
