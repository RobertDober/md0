defmodule Md0.MacroScanner do

  use Md0.Scanner.TableScanner

  @typep token :: {atom(), String.t, number()}
  @typep tokens :: list(token)
  @typep graphemes :: list(String.t)
  @typep scan_info :: {atom(), graphemes(), number(), IO.chardata(), tokens()}


  state :any do
    #           input, {next_state, emit_state(1), action}    (1) if different from current state
    deftransition " ", {:ws, nil, :emit_collect}
    deftransition "*", {:li, nil, :emit_collect}
    deftransition "`", {:back, nil, :emit_collect}
    deftransition true, {:any, nil, :collect}
    deftransition :eof, {:any, nil, :emit_return}
  end

  state :back do
    deftransition " ", {:ws, nil, :emit_collect}
    deftransition "*", {:li, nil, :emit_collect}
    deftransition "`", {:back, nil, :collect}
    deftransition true, {:any, nil, :emit_collect}
    deftransition :eof, {:back, nil, :emit_return}
  end

  state :indent do
    deftransition " ", {:indent, nil, :collect}
    deftransition "*", {:li, nil, :emit_collect}
    deftransition "`", {:back, nil, :emit_collect}
    deftransition true, {:any, nil, :emit_collect}
    deftransition :eof, {:indent, nil, :emit_return}
  end

  state :li do
    deftransition " ", {:rest, nil, :collect_emit}
    deftransition "*", {:star, nil, :collect}
    deftransition "`", {:back, :star, :emit_collect}
    deftransition true, {:any, :star, :emit_collect}
    deftransition :eof, {:any, :star, :emit_return}
  end

  state :rest do
    deftransition  " ", {:ws, nil, :collect}
    deftransition  "*", {:li, nil, :collect}
    deftransition  "`", {:back, nil, :collect}
    deftransition  true, {:any, nil, :collect}
    deftransition  :eof, {nil, nil, :return}
  end

  state :star do
    deftransition  " ", {:ws, nil, :emit_collect}
    deftransition  "*", {:star, nil, :collect}
    deftransition  "`", {:back, nil, :emit_collect}
    deftransition  true, {:any, nil, :emit_collect}
    deftransition  :eof, {:star, nil, :emit_return}
  end

  state :start do
    deftransition  " ", {:indent, nil, :collect}
    deftransition  "*", {:li, nil, :collect}
    deftransition  "`", {:back, nil, :collect}
    deftransition  true, {:any, nil, :collect}
    deftransition  :eof, {nil, nil, :return}
  end

  state :ws do
    deftransition  " ", {:ws, nil, :collect}
    deftransition  "*", {:li, nil, :emit_collect}
    deftransition  "`", {:back, nil, :emit_collect}
    deftransition  true, {:any, nil, :emit_collect}
    deftransition  :eof, {:ws, nil, :emit_return}
  end

end
