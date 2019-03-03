defmodule Md0.LexScanner do


  def scan_document(doc) do
    doc
    |> String.split(~r{\r\n?|\n})
    |> Enum.zip(Stream.iterate(1, &(&1 + 1)))
    |> Enum.flat_map(&lex_line/1)
  end
  
  defp lex_line({line, lnb}) do
    case line
      |> String.to_charlist
      |> :lexer.string do 
        {:ok, tokens, _} -> tokens |> Enum.reduce({[], 1}, &elixirize(&1, &2, lnb)) |> fst() |> Enum.reverse
    end
  end

  defp elixirize({token, _, chars}, {result, col}, lnb) do
    str = to_string(chars)
    {[{token, str, lnb, col} | result] , col + String.length(str)} 
  end

  defp fst({x,_}), do: x
end
