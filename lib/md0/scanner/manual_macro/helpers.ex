defmodule Md0.Scanner.ManualMacro.Helpers do
  

  @moduledoc """
  Helpers imported into the scanner module by Md0.Scanner.ManualMacro
  """

  @doc false
  def add_token(tokens, col, part, state) do
    string = part |> IO.iodata_to_binary() |> String.reverse()
    [{state, string, col} | tokens]
  end

  @doc false
  defp add_token_and_col(tokens, col, part, state) do
    with [{_, string, _} | _] = new_tokens <- add_token(tokens, col, part, state) do
      {col + String.length(string), new_tokens}
    end
  end
end
