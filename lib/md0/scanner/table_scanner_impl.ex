defmodule Md0.Scanner.TableScannerImpl do
  
  @typep token :: {atom(), String.t, number()}
  @typep tokens :: list(token)
  @typep graphemes :: list(String.t)
  @typep scan_info :: {atom(), graphemes(), number(), IO.chardata(), tokens()}



  def scan_line({line, lnb}, table),
    do: scan({:start, String.graphemes(line), 1, [], []}, table) |> Enum.map(&add_lnb(&1, lnb))

  defp add_lnb({tk, ct, col}, lnb), do: {tk, ct, lnb, col}

  @spec scan( scan_info(), map() ) :: tokens()
  defp scan(scan_info, table)
  defp scan({state, [], _, _, _} = info, table) do
    {type, token, action} = table[state][:eof]
    action.(token_to_info(info, token || type))
  end
  defp scan({state, [grapheme|_], _, _, _}=info, table) do
    {new_state, token, action} = (table[state][grapheme] || table[state][true])
    case action.(token_to_info(info, token)) do
      [_] = tokens -> tokens
      {_, input, col, partial, tokens} -> scan({new_state, input, col, partial, tokens}, table)
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
