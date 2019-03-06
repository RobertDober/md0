defmodule Md0.Scanner.ManualMacro do

  defmacro __before_compile__(env) do
    definitions = 
    Module.get_attribute(env.module, :_transitions) 
    |> Enum.map(&emit_scan_definition/1)
    |> IO.inspect

    quote do
      def scan(transition)
      def scan(:undefined), do: []
      unquote(definitions)
    end
  end

  defmacro __using__(_options) do
    quote do
      @before_compile unquote(__MODULE__)
      import unquote(__MODULE__)
      def scan_line(line), do:
      scan({:start, String.graphemes(line), 1, [], []})
      # def scan_line(line), do: scan({:start, String.graphemes(line), 1, [], []})
      Module.register_attribute __MODULE__, :_transitions, accumulate: true
      Module.register_attribute __MODULE__, :_current_state, accumulate: false
    end
  end


  defmacro state(state_id, do: block) do
    quote do
      Module.put_attribute __MODULE__, :_current_state, unquote(state_id)
      unquote(block)
      Module.put_attribute __MODULE__, :_current_state, nil
    end
  end

  defmacro on(grapheme, params), do: add_transition(:on, params, grapheme)

  defmacro empty(params), do: add_transition(:empty, params)

  defmacro anything(params), do: add_transition(:anything, params)

  defp add_transition(trans_type, params, grapheme \\ nil) do
    params1 =
    if is_list(params) do
      params|>Enum.into(%{})|>Macro.escape
    else
      params
    end

    quote do
      current_state = Module.get_attribute(__MODULE__, :_current_state)
      if current_state == nil do
        raise "Must not call #{unquote(trans_type)} outside of state macro"
      end
      @_transitions {unquote(trans_type), current_state, unquote(params1), unquote(grapheme)}
    end
  end


  def emit_scan_definition(transition)
  def emit_scan_definition({:empty, current_state, nil, nil}) do
    quote do
      def scan({ unquote(current_state), [], _, _, tokens}), do: Enum.revers(tokens) 
    end
  end
  def emit_scan_definition({:empty, current_state, _emit_state, nil}) do
    quote do
      def scan({unquote(current_state), [], col, partial, tokens }), do: emit_return(unquote(current_state), col, partial, tokens)
    end
  end
  def emit_scan_definition({:on, current_state, %{state: new_state}, grapheme}) do
    quote do
      def scan({unquote(current_state), [unquote(grapheme)|rest], col, partial, tokens}), do: scan({unquote(new_state), rest, col, [unquote(grapheme)|partial], tokens})
    end
  end

  #   def scan_document(doc) do
  #     doc
  #     |> String.split(~r{\r\n?|\n})
  #     |> Enum.zip(Stream.iterate(1, &(&1 + 1)))
  #     |> Enum.flat_map(&scan_line/1)
  #   end

  #   defp add_lnb({tk, ct, col}, lnb), do: {tk, ct, lnb, col}

  #   defp scan_line({line, lnb}),
  #     do: scan({ :start, String.graphemes(line), 1, [], [] }) |> Enum.map(&add_lnb(&1, lnb))

  #   defp collect_emit({emit_state, input, col, partial, tokens}, grapheme, new_state) do
  #     with rendered <- string_from([grapheme|partial]),
  #        do: scan({ new_state, input, col + String.length(rendered), [], [{emit_state, rendered, col} | tokens] })
  #   end

  #   defp emit_collect({emit_state,input, col, partial, tokens}, grapheme, new_state) do
  #     with rendered <- string_from(partial),
  #        do: scan({ new_state, input, col + String.length(rendered), [grapheme], [ {emit_state, rendered, col} | tokens] })
  #   end

  #   defp emit_return(state, col, partial, tokens), do: [{state, string_from(partial), col} | tokens] |> Enum.reverse

  #   defp string_from(partial), do: partial |> IO.iodata_to_binary() |> String.reverse()
end
