defmodule Md0.ManualScanner do

  @typep token :: {atom(), String.t, number()}
  @typep tokens :: list(token)
  @typep graphemes :: list(String.t)
  @typep scan_info :: {atom(), graphemes(), number(), IO.chardata(), tokens()}
  def scan_document(doc) do
    doc
    |> String.split(~r{\r\n?|\n})
    |> Enum.zip(Stream.iterate(1, &(&1 + 1)))
    |> Enum.flat_map(&scan_line/1)
  end

  defp add_lnb({tk, ct, col}, lnb), do: {tk, ct, lnb, col}

  @spec scan_line({String.t, number()}) :: tokens 
  defp scan_line({line, lnb}),
    do: scan({ :start, String.graphemes(line), 1, [], [] }) |> Enum.map(&add_lnb(&1, lnb))

  @spec scan( scan_info ) :: tokens
  defp scan(scan_state)

  defp scan({ :any, [], col, partial, tokens }), do: emit_return(:any, col, partial, tokens)
  defp scan({ :any, [" " | rest], col, partial, tokens }), do: emit_collect({:any, rest, col, partial, tokens}, " ", :ws)
  defp scan({ :any, ["*" | rest], col, partial, tokens }), do: emit_collect({:any, rest, col, partial, tokens},  "*",  :star)
  defp scan({ :any, ["`" | rest], col, partial, tokens }), do: emit_collect({:any, rest, col, partial, tokens},  "`",  :back)
  defp scan({ :any, [grapheme | rest], col, partial, tokens }), do: scan({ :any, rest, col, [grapheme | partial], tokens })

  defp scan({ :back, [], col, partial, tokens }), do: emit_return(:back, col, partial, tokens)
  defp scan({ :back, [" " | rest], col, partial, tokens }), do: emit_collect({:back, rest, col, partial, tokens},  " ",  :ws)
  defp scan({ :back, ["`" | rest], col, partial, tokens }), do: scan({ :back, rest, col, ["`"| partial], tokens })
  defp scan({ :back, ["*" | rest], col, partial, tokens }), do: emit_collect({:back, rest, col, partial, tokens},  "*",  :star)
  defp scan({ :back, [grapheme | rest], col, partial, tokens }), do: emit_collect({:back, rest, col, partial, tokens},  grapheme,  :any)

  defp scan({ :indent, [], col, partial, tokens }), do: emit_return(:indent, col, partial, tokens)
  defp scan({ :indent, [" " | rest], col, partial, tokens }), do: scan({ :indent, rest, col, [" " | partial], tokens })
  defp scan({ :indent, ["*" | rest], col, partial, tokens }), do: emit_collect({:indent, rest, col, partial, tokens},  "*",  :li)
  defp scan({ :indent, ["`" | rest], col, partial, tokens }), do: emit_collect({:indent, rest, col, partial, tokens},  "`",  :back )
  defp scan({ :indent, [grapheme | rest], col, partial, tokens }), do: emit_collect({:indent, rest, col, partial, tokens},  grapheme,  :any)

  defp scan({ :li, [], col, partial, tokens }), do: emit_return(:star, col, partial, tokens)
  defp scan({ :li, [" " | rest], col, partial, tokens }), do: collect_emit({:li, rest, col, partial, tokens},  " ",  :rest)
  defp scan({ :li, ["*" | rest], col, partial, tokens }), do: scan({ :star, rest, col, ["*"|partial], tokens })
  defp scan({ :li, ["`" | rest], col, partial, tokens }), do: emit_collect({:star, rest, col, partial, tokens},  "`",  :back)
  defp scan({ :li, [grapheme| rest], col, partial, tokens }), do: emit_collect({:star, rest, col, partial, tokens},  grapheme,  :any)

  defp scan({ :rest, [], _, _, tokens }), do: tokens |> Enum.reverse
  defp scan({ :rest, [" " | rest], col, partial, tokens }), do: scan({ :ws, rest, col, [" "|partial], tokens })
  defp scan({ :rest, ["*" | rest], col, partial, tokens }), do: scan({ :star, rest, col, ["*"|partial], tokens })
  defp scan({ :rest, ["`" | rest], col, partial, tokens }), do: scan({ :back, rest, col, ["`"|partial], tokens })
  defp scan({ :rest, [grapheme | rest], col, partial, tokens }), do: scan({ :any, rest, col, [grapheme|partial], tokens })

  defp scan({ :star, [], col, partial, tokens }), do: emit_return(:star, col, partial, tokens)
  defp scan({ :star, [" " | rest], col, partial, tokens }), do: emit_collect({:star, rest, col, partial, tokens},  " ",  :ws)
  defp scan({ :star, ["`" | rest], col, partial, tokens }), do: emit_collect({:star, rest, col, partial, tokens},  "`",  :back)
  defp scan({ :star, ["*" | rest], col, partial, tokens }), do: scan({ :star, rest, col, ["*"| partial], tokens })
  defp scan({ :star, [grapheme | rest], col, partial, tokens }), do: emit_collect({:star, rest, col, partial, tokens},  grapheme,  :any)

  defp scan({ :start, [], _, _, _ }), do: []
  defp scan({ :start, [" " | rest], col, partial, tokens }), do: scan({ :indent, rest, col, [" " | partial], tokens })
  defp scan({ :start, ["*" | rest], col, partial, tokens }), do: scan({ :li, rest, col, ["*" | partial], tokens })
  defp scan({ :start, ["`" | rest], col, partial, tokens }), do: scan({ :back, rest, col, ["`" | partial], tokens })
  defp scan({ :start, [grapheme | rest], col, partial, tokens }), do: scan({ :any, rest, col, [grapheme | partial], tokens })

  defp scan({ :ws, [], col, partial, tokens }), do: emit_return(:ws, col, partial, tokens)
  defp scan({ :ws, [" " | rest], col, partial, tokens }), do: scan({ :ws, rest, col, [" "| partial], tokens })
  defp scan({ :ws, ["`" | rest], col, partial, tokens }), do: emit_collect({:ws, rest, col, partial, tokens},  "`",  :back)
  defp scan({ :ws, ["*" | rest], col, partial, tokens }), do: emit_collect({:ws, rest, col, partial, tokens},  "*",  :li)
  defp scan({ :ws, [grapheme | rest], col, partial, tokens }), do: emit_collect({:ws, rest, col, partial, tokens},  grapheme,  :any)

  @spec collect_emit( scan_info(), IO.chardata, atom() ) :: tokens()
  defp collect_emit({emit_state, input, col, partial, tokens}, grapheme, new_state) do
    with rendered <- string_from([grapheme|partial]),
       do: scan({ new_state, input, col + String.length(rendered), [], [{emit_state, rendered, col} | tokens] })
  end

  @spec emit_collect( scan_info(), IO.chardata, atom() ) :: tokens()
  defp emit_collect({emit_state,input, col, partial, tokens}, grapheme, new_state) do
    with rendered <- string_from(partial),
       do: scan({ new_state, input, col + String.length(rendered), [grapheme], [ {emit_state, rendered, col} | tokens] })
  end

  defp emit_return(state, col, partial, tokens), do: [{state, string_from(partial), col} | tokens] |> Enum.reverse

  defp string_from(partial), do: partial |> IO.iodata_to_binary() |> String.reverse()
end
