defmodule Md0.RgxScanner do

  use Md0.Scanner.Macros

  @moduledoc """
  A lexical Analyzer of markdown documents
  """

  def scan_document(doc) do
    doc
    |> String.split(~r{\r\n?|\n})
    |> Enum.zip(Stream.iterate(1, &(&1+1)))
    |> Enum.flat_map(&scan_line/1)
  end
  


  defp scan_line({line, lnb}) do
    with tokens <- tokenize(lnb, line, []), do: tokens |> Enum.reverse
  end


  defp tokenize(lnb, line, tokens, col \\ 1)
  defp tokenize(lnb, "", tokens,  col), do: tokens
  defp tokenize(lnb, line, tokens, col) do
    with {{sym, txt, col1}, rest, new_col} <- get_token(line, col), do: tokenize(lnb, rest, [{sym, txt, lnb, col1}|tokens], new_col)
  end


  # We define token in the *reverse* order they are searched, thusly
  # it would be best to move the most frequent but also the
  # not too expensive to check downwards, the actual order
  # might not be ideal for the typical Elixir docstrings.
  # In case of performance issues, some research might be
  # in order.
  @always_text "[^-\\]\\\\|+*~<>{\\}[`!'==#=\\s" <> ~s{"} <> "]"
  @text_after  "[^-\\]\\\\|+*~<>{}[`!]"
  deftoken :any, "[^\\s`*]+"
  deftoken :back,   "`+"
  deftoken :star,   "\\*+"
  deftoken :ws,     "\\s+"

  defstarttoken :indent, "\\s+"
  defstarttoken :li, "\\s*\\*\\s+"


  defp get_token(line, col) do
    match(line, col) || {{:error, line, col}, "", col}
  end

  defp match(line, 1) do
    @_defined_start_tokens
    |> Enum.find_value(&match_token(&1, line, 1))
    ||
    match_later(line, 1)
  end
  defp match(line, col), do: match_later(line, col)

  defp match_later(line, col) do
    @_defined_tokens
    |> Enum.find_value(&match_token(&1, line, col))
  end

  defp match_token( {token_name, token_rgx}, line, col ) do
    case Regex.run(token_rgx, line) do
      [_, token_string, rest] -> {{token_name, token_string, col}, rest, col + String.length(token_string)} 
      _                       -> nil
    end
  end

end
