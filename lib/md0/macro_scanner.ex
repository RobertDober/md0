defmodule Md0.MacroScanner do

  use Md0.Scanner.TableScanner

  @typep token :: {atom(), String.t, number()}
  @typep tokens :: list(token)
  @typep graphemes :: list(String.t)
  @typep scan_info :: {atom(), graphemes(), number(), IO.chardata(), tokens()}


  #             state input {next_state, emit_state(1), action}    (1) if different from current state
  deftransition :any, " ", {:ws, nil, :emit_collect}
  deftransition :any, "*", {:li, nil, :emit_collect}
  deftransition :any, "`", {:back, nil, :emit_collect}
  deftransition :any, true, {:any, nil, :collect}
  deftransition :any, :eof, {:any, nil, :emit_return}

  deftransition :back, " ", {:ws, nil, :emit_collect}
  deftransition :back, "*", {:li, nil, :emit_collect}
  deftransition :back, "`", {:back, nil, :collect}
  deftransition :back, true, {:any, nil, :emit_collect}
  deftransition :back, :eof, {:back, nil, :emit_return}

  deftransition :indent, " ", {:indent, nil, :collect}
  deftransition :indent, "*", {:li, nil, :emit_collect}
  deftransition :indent, "`", {:back, nil, :emit_collect}
  deftransition :indent, true, {:any, nil, :emit_collect}
  deftransition :indent, :eof, {:indent, nil, :emit_return}

  deftransition :li, " ", {:rest, nil, :collect_emit}
  deftransition :li, "*", {:star, nil, :collect}
  deftransition :li, "`", {:back, :star, :emit_collect}
  deftransition :li, true, {:any, :star, :emit_collect}
  deftransition :li, :eof, {:any, :star, :emit_return}

  deftransition :rest, " ", {:ws, nil, :collect}
  deftransition :rest, "*", {:li, nil, :collect}
  deftransition :rest, "`", {:back, nil, :collect}
  deftransition :rest, true, {:any, nil, :collect}
  deftransition :rest, :eof, {nil, nil, :return}

  deftransition :star, " ", {:ws, nil, :emit_collect}
  deftransition :star, "*", {:star, nil, :collect}
  deftransition :star, "`", {:back, nil, :emit_collect}
  deftransition :star, true, {:any, nil, :emit_collect}
  deftransition :star, :eof, {:star, nil, :emit_return}

  deftransition :start, " ", {:indent, nil, :collect}
  deftransition :start, "*", {:li, nil, :collect}
  deftransition :start, "`", {:back, nil, :collect}
  deftransition :start, true, {:any, nil, :collect}
  deftransition :start, :eof, {nil, nil, :return}

  deftransition :ws, " ", {:ws, nil, :collect}
  deftransition :ws, "*", {:li, nil, :emit_collect}
  deftransition :ws, "`", {:back, nil, :emit_collect}
  deftransition :ws, true, {:any, nil, :emit_collect}
  deftransition :ws, :eof, {:ws, nil, :emit_return}

end
