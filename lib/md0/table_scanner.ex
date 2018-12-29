defmodule Md0.TableScanner do

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

  @table %{
    any: %{
      # Input next_state, emit_state(1), actions    (1) if different from current state
      " " => {:ws, nil, &__MODULE__.emit_collect/1},
      "*" => {:li, nil, &__MODULE__.emit_collect/1},
      "`" => {:back, nil, &__MODULE__.emit_collect/1},
      true => {:any, nil, &__MODULE__.collect/1},
      :eof => {:any, nil, &__MODULE__.emit_return/1}
    },
    back: %{
      " " => {:ws, nil, &__MODULE__.emit_collect/1},
      "*" => {:li, nil, &__MODULE__.emit_collect/1},
      "`" => {:back, nil, &__MODULE__.collect/1},
      true => {:any, nil, &__MODULE__.emit_collect/1},
      :eof => {:back, nil, &__MODULE__.emit_return/1}
    },
    indent: %{
      " " => {:indent, nil, &__MODULE__.collect/1},
      "*" => {:li, nil, &__MODULE__.emit_collect/1},
      "`" => {:back, nil, &__MODULE__.emit_collect/1},
      true => {:any, nil, &__MODULE__.emit_collect/1},
      :eof => {:indent, nil, &__MODULE__.emit_return/1}
    },
    li: %{
      " " => {:rest, nil, &__MODULE__.collect_emit/1},
      "*" => {:star, nil, &__MODULE__.collect/1},
      "`" => {:back, :star, &__MODULE__.emit_collect/1},
      true => {:any, :star, &__MODULE__.emit_collect/1},
      :eof => {:any, :star, &__MODULE__.emit_return/1},
    },
    rest: %{
      " " => {:ws, nil, &__MODULE__.collect/1},
      "*" => {:li, nil, &__MODULE__.collect/1},
      "`" => {:back, nil, &__MODULE__.collect/1},
      true => {:any, nil, &__MODULE__.collect/1},
      :eof => {nil, nil, &__MODULE__.return/1}
    },
    star: %{
      " " => {:ws, nil, &__MODULE__.emit_collect/1},
      "*" => {:star, nil, &__MODULE__.collect/1},
      "`" => {:back, nil, &__MODULE__.emit_collect/1},
      true => {:any, nil, &__MODULE__.emit_collect/1},
      :eof => {:star, nil, &__MODULE__.emit_return/1}
    },
    start: %{
      " " => {:indent, nil, &__MODULE__.collect/1},
      "*" => {:li, nil, &__MODULE__.collect/1},
      "`" => {:back, nil, &__MODULE__.collect/1},
      true => {:any, nil, &__MODULE__.collect/1},
      :eof => {nil, nil, &__MODULE__.return/1}
    },
    ws: %{
      " " => {:ws, nil, &__MODULE__.collect/1},
      "*" => {:li, nil, &__MODULE__.emit_collect/1},
      "`" => {:back, nil, &__MODULE__.emit_collect/1},
      true => {:any, nil, &__MODULE__.emit_collect/1},
      :eof => {:ws, nil, &__MODULE__.emit_return/1}
    },
  }

  defp scan_line({line, lnb}),
    do: scan({:start, String.graphemes(line), 1, [], []}) |> Enum.map(&add_lnb(&1, lnb))

  @spec scan( scan_info() ) :: tokens()
  defp scan(scan_info)
  defp scan({state, [], _, _, _} = info) do
    {type, token, action} = @table[state][:eof]
    action.(token_to_info(info, token || type))
  end
  defp scan({state, [grapheme|_], _, _, _}=info) do
    {new_state, token, action} = (@table[state][grapheme] || @table[state][true])
    case action.(token_to_info(info, token)) do
      [_] = tokens -> tokens
      {_, input, col, partial, tokens} -> scan({new_state, input, col, partial, tokens})
    end
  end

  @doc false
  @spec collect( scan_info() ) :: scan_info()
  def collect({state, [grapheme|rest], col, partial, tokens}), do: {state, rest, col, [grapheme|partial], tokens}

  @spec collect_emit( scan_info() ) :: tokens()
  def collect_emit({emit_state, [grapheme | rest ], col, partial, tokens}) do
    with rendered <- string_from([grapheme|partial]),
       do: { nil, rest, col + String.length(rendered), [], [{emit_state, rendered, col} | tokens] }
  end

  @doc false
  @spec emit_collect( scan_info() ) :: scan_info()
  def emit_collect({emit_state,[grapheme|input], col, partial, tokens}) do
    rendered  = string_from(partial) 
    {nil, input, col + String.length(rendered), [grapheme], [{emit_state, rendered, col}|tokens]}
  end

  @spec emit_return( scan_info() ) :: tokens()
  def emit_return({state, _, col, partial, tokens}), do: [{state, string_from(partial), col} | tokens] |> Enum.reverse

  @spec return( scan_info() ) :: tokens()
  def return({_, _, _, _, tokens}), do: tokens |> Enum.reverse

  defp string_from(partial), do: partial |> IO.iodata_to_binary() |> String.reverse()

  defp token_to_info(info, token)
  defp token_to_info(info, nil), do: info
  defp token_to_info({_,input, col, partial, tokens}, token), do: {token ,input, col, partial, tokens}
end
