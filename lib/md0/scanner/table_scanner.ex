defmodule Md0.Scanner.TableScanner do

  defmacro __before_compile__(_env) do
    quote do
      def scan_document(doc) do
        doc
        |> String.split(~r{\r\n?|\n})
        |> Enum.zip(Stream.iterate(1, &(&1 + 1)))
        |> Enum.flat_map(&scan_line(&1, @table))
      end
    end
  end

  defmacro __using__(_options) do
    quote do
      import Md0.Scanner.TableScannerImpl, only: [scan_line: 2]
      @before_compile unquote(__MODULE__)
    end
  end
  
end
