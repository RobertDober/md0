defmodule Md0.Scanner.TableScanner do

  import Md0.Scanner.TableScanner.Helper

  defmacro __before_compile__(_env) do
    quote do
      def scan_document(doc) do
        table = unquote(__MODULE__).transform_table(@_scan_table)
        doc
        |> String.split(~r{\r\n?|\n})
        |> Enum.zip(Stream.iterate(1, &(&1 + 1)))
        |> Enum.flat_map(&scan_line(&1, table))
      end
    end
  end

  defmacro __using__(_options) do
    quote do
      import Md0.Scanner.TableScannerImpl, only: [scan_line: 2]
      import unquote(__MODULE__)
      @before_compile unquote(__MODULE__)
      Module.register_attribute __MODULE__, :_scan_table, accumulate: true
      Module.register_attribute __MODULE__, :_current_state, accumulate: false
    end
  end

  defmacro state(current_state, do: code) do
    quote  do
      Module.put_attribute(__MODULE__,  :_current_state, unquote(current_state))
      unquote(code)
      Module.put_attribute(__MODULE__, :_current_state, nil)
    end
  end

  defmacro deftransition(current_grapheme, transition) do
    quote bind_quoted: [current_grapheme: current_grapheme, transition: transition] do
      current_state = Module.get_attribute(__MODULE__, :_current_state)
      if current_state == nil do
        raise "`deftransition` can only be used inside the state macro"
      end
      @_scan_table {current_state, current_grapheme, transition}
    end
  end

  def transform_table(accumulated_transactions), do: accu_table_to_map(accumulated_transactions)

end
