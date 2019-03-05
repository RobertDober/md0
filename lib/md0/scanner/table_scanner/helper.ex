defmodule Md0.Scanner.TableScanner.Helper do

  alias Md0.Scanner.TableScannerImpl, as: Scanner
  
  @legal_actions %{
    collect: &Scanner.collect/1,
    emit_collect: &Scanner.emit_collect/1,
    emit_return: &Scanner.emit_return/1,
    return: &Scanner.return/1
  }

  @doc """
  Transforms the accumulated table of format

        [
          { state, grapheme, actions }...
        ]

  into a map of format

        %{
          state => %{
             grapheme => normalized_action
          }
        }
  """
  def accu_table_to_map(accumulated_transformations) do
    _transform(accumulated_transformations, %{})
  end


  defp _action({state, emit_state, action}) do
    action_fn = Map.get(@legal_actions, action)
    if action_fn do
      {state, emit_state, action_fn}
    else
      raise "Error, illegal action #{action}, supported actions are #{Map.keys(@legal_actions)|>List.join(", ")}"
    end
  end

  defp _add_transform(transform, result)
  defp _add_transform({state, grapheme, {new_state, action}}, result), do:
    _add_transform({state, grapheme, {new_state, new_state, action}}, result)
  defp _add_transform({state, grapheme, transform}, result), do:
    nil

                     
  defp _transform(transaformations, result)
  defp _transform([], result), do: result
  defp _transform([transform|rest], result), do: _transform(rest, _add_transform(transform, result))

end
