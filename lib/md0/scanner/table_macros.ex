defmodule Md0.Scanner.TableMacros do
  
  defmacro __using__(_options) do
    quote do
      unquote(InjectedFns.inject_att)
      # import unquote(__MODULE__)
      Module.put_attribute unquote(__MODULE__), :table, %{} 
    end
  end

  @doc nil
  defmacro deftransition(state, grapheme, {new_state, action}, emit_state \\ nil) do
    quote bind_quoted: [action: action, emit_state: emit_state, grapheme: grapheme, new_state: new_state, state: state] do
      table = Module.get_attribute(__MODULE__, :table)
      unless table[state], do: Map.put(table, state, %{})
      Map.put(table[state], grapheme, {new_state, emit_state, action})
      Module.put_attribute(__MODULE__, :table, table)
    end
  end


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
  @doc false
  @spec collect( scan_info() ) :: scan_info()
  def collect({state, [grapheme|rest], col, partial, tokens}), do: {state, rest, col, [grapheme|partial], tokens}

  @doc false
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

  @doc false
  @spec emit_return( scan_info() ) :: tokens()
  def emit_return({state, _, col, partial, tokens}), do: [{state, string_from(partial), col} | tokens] |> Enum.reverse

  @doc false
  @spec return( scan_info() ) :: tokens()
  def return({_, _, _, _, tokens}), do: tokens |> Enum.reverse

  defp add_lnb({tk, ct, col}, lnb), do: {tk, ct, lnb, col}

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

  defp string_from(partial), do: partial |> IO.iodata_to_binary() |> String.reverse()

  defp token_to_info(info, token)
  defp token_to_info(info, nil), do: info
  defp token_to_info({_,input, col, partial, tokens}, token), do: {token ,input, col, partial, tokens}
end
