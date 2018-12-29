defmodule Md0.TableScanner do
  def scan_document(doc) do
    doc
    |> String.split(~r{\r\n?|\n})
    |> Enum.zip(Stream.iterate(1, &(&1 + 1)))
    |> Enum.flat_map(&scan_line/1)
  end

  defp add_lnb({tk, ct, col}, lnb), do: {tk, ct, lnb, col}

  defp scan_line({line, lnb}),
    do: scan(:start, String.graphemes(line), 1, [], []) |> Enum.map(&add_lnb(&1, lnb))

  defp scan(state, input, col, partial, tokens)

  defp scan(:any, [], col, partial, tokens), do: emit_return(:any, col, partial, tokens)
  defp scan(:any, [" " | rest], col, partial, tokens), do: emit_collect(:any, :ws, rest, " ", col, partial, tokens)
  defp scan(:any, ["*" | rest], col, partial, tokens), do: emit_collect(:any, :star, rest, "*", col, partial, tokens)
  defp scan(:any, ["`" | rest], col, partial, tokens), do: emit_collect(:any, :back, rest, "`", col, partial, tokens)
  defp scan(:any, [grapheme | rest], col, partial, tokens), do: scan(:any, rest, col, [grapheme | partial], tokens)

  defp scan(:back, [], col, partial, tokens), do: emit_return(:back, col, partial, tokens)
  defp scan(:back, [" " | rest], col, partial, tokens), do: emit_collect(:back, :ws, rest, " ", col, partial, tokens)
  defp scan(:back, ["`" | rest], col, partial, tokens), do: scan(:back, rest, col, ["`"| partial], tokens)
  defp scan(:back, ["*" | rest], col, partial, tokens), do: emit_collect(:back, :star, rest, "*", col, partial, tokens)
  defp scan(:back, [grapheme | rest], col, partial, tokens), do: emit_collect(:back, :any, rest, grapheme, col, partial, tokens)

  defp scan(:indent, [], col, partial, tokens), do: emit_return(:indent, col, partial, tokens)
  defp scan(:indent, [" " | rest], col, partial, tokens), do: scan(:indent, rest, col, [" " | partial], tokens)
  defp scan(:indent, ["*" | rest], col, partial, tokens), do: emit_collect(:indent, :li, rest, "*", col, partial, tokens) 
  defp scan(:indent, ["`" | rest], col, partial, tokens), do: emit_collect(:indent, :back, rest, "`", col, partial, tokens) 
  defp scan(:indent, [grapheme | rest], col, partial, tokens), do: emit_collect(:indent, :any, rest, grapheme, col, partial, tokens) 

  defp scan(:li, [], col, partial, tokens), do: emit_return(:star, col, partial, tokens)
  defp scan(:li, [" " | rest], col, partial, tokens), do: collect_emit(:li, :rest, rest, " ", col, partial, tokens) 
  defp scan(:li, ["*" | rest], col, partial, tokens), do: scan(:star, rest, col, ["*"|partial], tokens)
  defp scan(:li, ["`" | rest], col, partial, tokens), do: emit_collect(:star, :back, rest, "`", col, partial, tokens)
  defp scan(:li, [grapheme| rest], col, partial, tokens), do: emit_collect(:star, :any, rest, grapheme, col, partial, tokens)

  defp scan(:rest, [], _, _, tokens), do: tokens |> Enum.reverse
  defp scan(:rest, [" " | rest], col, partial, tokens), do: scan(:ws, rest, col, [" "|partial], tokens)
  defp scan(:rest, ["*" | rest], col, partial, tokens), do: scan(:star, rest, col, ["*"|partial], tokens)
  defp scan(:rest, ["`" | rest], col, partial, tokens), do: scan(:back, rest, col, ["`"|partial], tokens)
  defp scan(:rest, [grapheme | rest], col, partial, tokens), do: scan(:any, rest, col, [grapheme|partial], tokens)

  defp scan(:star, [], col, partial, tokens), do: emit_return(:star, col, partial, tokens)
  defp scan(:star, [" " | rest], col, partial, tokens), do: emit_collect(:star, :ws, rest, " ", col, partial, tokens)
  defp scan(:star, ["`" | rest], col, partial, tokens), do: emit_collect(:star, :back, rest, "`", col, partial, tokens)
  defp scan(:star, ["*" | rest], col, partial, tokens), do: scan(:star, rest, col, ["*"| partial], tokens)
  defp scan(:star, [grapheme | rest], col, partial, tokens), do: emit_collect(:star, :any, rest, grapheme, col, partial, tokens)

  defp scan(:start, [], _, _, _), do: []
  defp scan(:start, [" " | rest], col, partial, tokens), do: scan(:indent, rest, col, [" " | partial], tokens)
  defp scan(:start, ["*" | rest], col, partial, tokens), do: scan(:li, rest, col, ["*" | partial], tokens)
  defp scan(:start, ["`" | rest], col, partial, tokens), do: scan(:back, rest, col, ["`" | partial], tokens)
  defp scan(:start, [grapheme | rest], col, partial, tokens), do: scan(:any, rest, col, [grapheme | partial], tokens)

  defp scan(:ws, [], col, partial, tokens), do: emit_return(:ws, col, partial, tokens)
  defp scan(:ws, [" " | rest], col, partial, tokens), do: scan(:ws, rest, col, [" "| partial], tokens)
  defp scan(:ws, ["`" | rest], col, partial, tokens), do: emit_collect(:ws, :back, rest, "`", col, partial, tokens)
  defp scan(:ws, ["*" | rest], col, partial, tokens), do: emit_collect(:ws, :li, rest, "*", col, partial, tokens)
  defp scan(:ws, [grapheme | rest], col, partial, tokens), do: emit_collect(:ws, :any, rest, grapheme, col, partial, tokens)

  defp collect_emit(emit_state, new_state, input, grapheme, col, partial, tokens) do
    with rendered <- string_from([grapheme|partial]),
       do: scan(new_state, input, col + String.length(rendered), [], [{emit_state, rendered, col} | tokens])
  end

  defp emit_collect(emit_state, new_state, input, grapheme, col, partial, tokens) do
    with rendered <- string_from(partial),
       do: scan(new_state, input, col + String.length(rendered), [grapheme], [ {emit_state, rendered, col} | tokens])
  end

  defp emit_return(state, col, partial, tokens), do: [{state, string_from(partial), col} | tokens] |> Enum.reverse

  defp string_from(partial), do: partial |> IO.iodata_to_binary() |> String.reverse()
end
