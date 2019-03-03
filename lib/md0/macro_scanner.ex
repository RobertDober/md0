defmodule Md0.MacroScanner do

  use Md0.Scanner.TableScanner

  @typep token :: {atom(), String.t, number()}
  @typep tokens :: list(token)
  @typep graphemes :: list(String.t)
  @typep scan_info :: {atom(), graphemes(), number(), IO.chardata(), tokens()}

  @table %{
    any: %{
      # Input next_state, emit_state(1), actions    (1) if different from current state
      " " => {:ws, nil, &Md0.Scanner.TableScannerImpl.emit_collect/1},
      "*" => {:li, nil, &Md0.Scanner.TableScannerImpl.emit_collect/1},
      "`" => {:back, nil, &Md0.Scanner.TableScannerImpl.emit_collect/1},
      true => {:any, nil, &Md0.Scanner.TableScannerImpl.collect/1},
      :eof => {:any, nil, &Md0.Scanner.TableScannerImpl.emit_return/1}
    },

    back: %{
      " " => {:ws, nil, &Md0.Scanner.TableScannerImpl.emit_collect/1},
      "*" => {:li, nil, &Md0.Scanner.TableScannerImpl.emit_collect/1},
      "`" => {:back, nil, &Md0.Scanner.TableScannerImpl.collect/1},
      true => {:any, nil, &Md0.Scanner.TableScannerImpl.emit_collect/1},
      :eof => {:back, nil, &Md0.Scanner.TableScannerImpl.emit_return/1}
    },
    indent: %{
      " " => {:indent, nil, &Md0.Scanner.TableScannerImpl.collect/1},
      "*" => {:li, nil, &Md0.Scanner.TableScannerImpl.emit_collect/1},
      "`" => {:back, nil, &Md0.Scanner.TableScannerImpl.emit_collect/1},
      true => {:any, nil, &Md0.Scanner.TableScannerImpl.emit_collect/1},
      :eof => {:indent, nil, &Md0.Scanner.TableScannerImpl.emit_return/1}
    },
    li: %{
      " " => {:rest, nil, &Md0.Scanner.TableScannerImpl.collect_emit/1},
      "*" => {:star, nil, &Md0.Scanner.TableScannerImpl.collect/1},
      "`" => {:back, :star, &Md0.Scanner.TableScannerImpl.emit_collect/1},
      true => {:any, :star, &Md0.Scanner.TableScannerImpl.emit_collect/1},
      :eof => {:any, :star, &Md0.Scanner.TableScannerImpl.emit_return/1},
    },
    rest: %{
      " " => {:ws, nil, &Md0.Scanner.TableScannerImpl.collect/1},
      "*" => {:li, nil, &Md0.Scanner.TableScannerImpl.collect/1},
      "`" => {:back, nil, &Md0.Scanner.TableScannerImpl.collect/1},
      true => {:any, nil, &Md0.Scanner.TableScannerImpl.collect/1},
      :eof => {nil, nil, &Md0.Scanner.TableScannerImpl.return/1}
    },
    star: %{
      " " => {:ws, nil, &Md0.Scanner.TableScannerImpl.emit_collect/1},
      "*" => {:star, nil, &Md0.Scanner.TableScannerImpl.collect/1},
      "`" => {:back, nil, &Md0.Scanner.TableScannerImpl.emit_collect/1},
      true => {:any, nil, &Md0.Scanner.TableScannerImpl.emit_collect/1},
      :eof => {:star, nil, &Md0.Scanner.TableScannerImpl.emit_return/1}
    },
    start: %{
      " " => {:indent, nil, &Md0.Scanner.TableScannerImpl.collect/1},
      "*" => {:li, nil, &Md0.Scanner.TableScannerImpl.collect/1},
      "`" => {:back, nil, &Md0.Scanner.TableScannerImpl.collect/1},
      true => {:any, nil, &Md0.Scanner.TableScannerImpl.collect/1},
      :eof => {nil, nil, &Md0.Scanner.TableScannerImpl.return/1}
    },
    ws: %{
      " " => {:ws, nil, &Md0.Scanner.TableScannerImpl.collect/1},
      "*" => {:li, nil, &Md0.Scanner.TableScannerImpl.emit_collect/1},
      "`" => {:back, nil, &Md0.Scanner.TableScannerImpl.emit_collect/1},
      true => {:any, nil, &Md0.Scanner.TableScannerImpl.emit_collect/1},
      :eof => {:ws, nil, &Md0.Scanner.TableScannerImpl.emit_return/1}
    },
  }

end
