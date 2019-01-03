defmodule InjectedFns do
  @doc false
  def inject_att, do:
  {:def, [context: Elixir, import: Kernel],
   [
     {:table, [context: Elixir], Elixir},
     [
       do: {:@, [context: Elixir, import: Kernel],
	[{:table, [context: Elixir], Elixir}]}
     ]
   ]}
end
