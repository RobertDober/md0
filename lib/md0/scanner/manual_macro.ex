defmodule Md0.Scanner.ManualMacro do

#   defmacro __before_compile__(_env) do
#   end

#   defmacro __using__(_options) do
#     quote do
#       @before_compile unquote(__MODULE__)
#       import unquote(__MODULE__)
#     end
#   end

#   def scan_document(doc) do
#     doc
#     |> String.split(~r{\r\n?|\n})
#     |> Enum.zip(Stream.iterate(1, &(&1 + 1)))
#     |> Enum.flat_map(&scan_line/1)
#   end

#   defp add_lnb({tk, ct, col}, lnb), do: {tk, ct, lnb, col}

#   defp scan_line({line, lnb}),
#     do: scan({ :start, String.graphemes(line), 1, [], [] }) |> Enum.map(&add_lnb(&1, lnb))
  
#   defp collect_emit({emit_state, input, col, partial, tokens}, grapheme, new_state) do
#     with rendered <- string_from([grapheme|partial]),
#        do: scan({ new_state, input, col + String.length(rendered), [], [{emit_state, rendered, col} | tokens] })
#   end

#   defp emit_collect({emit_state,input, col, partial, tokens}, grapheme, new_state) do
#     with rendered <- string_from(partial),
#        do: scan({ new_state, input, col + String.length(rendered), [grapheme], [ {emit_state, rendered, col} | tokens] })
#   end

#   defp emit_return(state, col, partial, tokens), do: [{state, string_from(partial), col} | tokens] |> Enum.reverse

#   defp string_from(partial), do: partial |> IO.iodata_to_binary() |> String.reverse()
end
