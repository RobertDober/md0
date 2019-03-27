defmodule Md0.Scanner.ManualMacro do

  defmacro __before_compile__(env) do
    definitions = 
    Module.get_attribute(env.module, :_transitions) 
    |> Enum.map(&emit_scan_definition/1)

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

  defmacro on(grapheme, params), do: add_transition(grapheme, params)

  defmacro empty(params), do: add_transition(:empty, params)

  defmacro anything(params), do: add_transition(:anything, params)

  @default_params %{
    advance: true,
    collect: true,
    emit: nil,
    state: nil
  }
  defp add_transition(trans_type, params) do
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
      @_transitions {unquote(trans_type), current_state, unquote(params1)}
    end
  end


  defp emit_scan_definition(transition)
  defp emit_scan_definition({:empty, current_state, params}), do:
    emit_empty_state_def(current_state, params)
  defp emit_scan_definition({trigger, current_state, %{state: :halt} = params}), do:
    emit_halt_state_def(trigger, current_state, params)
  defp emit_scan_definition({trigger, current_state, %{advance: false} = params}), do:
    emit_no_advance_state_def(trigger, currrent_state, params)
  defp emit_scan_definition({:anything, current_state, params}), do:
    emit_advance_any_state_def(current_state, params)
  defp emit_scan_definition({grapheme, current_state, params}), do:
    emit_advance_on_state_def(grapheme, current_state, params)


  defp emit_empty_state_def(current_state, params)
  defp emit_empty_state_def(cs, %{emit: nil, state: :halt}), do:
    quote do
      defp scan(unquote(cs), [], col, part, tokens), do: Enum.reverse(tokens)
    end
  defp emit_empty_state_def(cs, %{emit: emit, state: :halt}), do:
    quote do
      defp scan(unquote(cs), [], col, part, tokens), do: Enum.reverse(add_token(tokens, col, part, unquote(emit)))
    end
  defp emit_empty_state_def(cs, %{emit: nil, state: ns}) do
    if (ns || cs) == cs do
      raise "Illegal loop at EOI with state: #{cs}"
    else
      quote do
        defp scan(unquote(cs), [], col, part, tokens), do: scan(unquote(ns), [], col, part, tokens)
      end
    end
  end
  defp emit_empty_state_def(cs, %{emit: emit, state: ns}) do
    if (ns || cs) == cs do
      raise "Illegal loop at EOI with state: #{cs}"
    else
      quote do
        defp scan(unquote(cs), [], col, part, tokens) do
          {nc, nts} = add_token_and_col(tokens, col, part, unquote(emit))
          scan(unquote(ns), [], nc, [], nts)
        end
      end
    end
  end

  defp emit_halt_state_def(trigger, current_state, params)
  defp emit_halt_state_def(_, cs, %{collect: false, emit: nil}), do:
    quote do
      def scan(unquote(cs), _, _, _, tokens), do: Enum.reverse(tokens)
    end
  defp emit_halt_state_def(_, cs, %{collect: false, emit: emit}), do:
    quote do
      def scan(unquote(cs), _, col, parts, tokens), do: Enum.reverse(add_token(tokens, col, part, unquote(emit)))
    end
  defp emit_halt_state_def(:anything, cs, %{collect: :before, emit: emit}), do:
    quote do
      def scan(unquote(cs), [h|_], col, parts, tokens), do:
        Enum.reverse(add_token(tokens, col, [h|part], unquote(emit)))
    end
  defp emit_halt_state_def(grapheme, cs, %{collect: :before, emit: emit}), do:
    quote do
      def scan(unquote(cs), [unquote(grapheme)|_], col, parts, tokens), do:
        Enum.reverse(add_token(tokens, col, [unquote(grapheme)|part], unquote(emit)))
    end
  defp emit_halt_state_def(_, cs, _), do:
    raise "Error collect does not make any sense in this halting context of state: #{cs}"
    
  defp emit_no_advance_state_def(trigger, current_state, params)
  defp emit_no_advance_state_def(_, cs, %{state: nil}), do: raise "Error looping with no advance in state: #{cs}"
  defp emit_no_advance_state_def(_, cs, %{state: ns}) when ns == cs do
    raise "Error looping with no advance in state: #{cs}"
  end
  defp emit_no_advance_state_def(:anything, cs, %{collect: false, emit: nil, state: ns}), do:
    quote do
      def scan(unquote(cs), input, col, part, tokens), do: scan(unquote(ns), input, col, part, tokens)
    end
  defp emit_no_advance_state_def(grapheme, cs, %{collect: false, emit: nil, state: ns}), do:
    quote do
      def scan(unquote(cs), [unquote(grapheme)|_]=input, col, part, tokens), do: scan(unquote(ns), input, col, part, tokens)
    end
  defp emit_no_advance_state_def(:anything, cs, %{emit: nil, state: ns}), do:
    quote do
      def scan(unquote(cs), [head|_]=input, col, part, tokens), do: scan(unquote(ns), input, col, [head|part], tokens)
    end
  defp emit_no_advance_state_def(grapheme, cs, %{emit: nil, state: ns}), do:
    quote do
      def scan(unquote(cs), [unquote(grapheme)|_]=input, col, part, tokens), do: scan(unquote(ns), input, col, [unquote(grapheme)|part], tokens)
    end
  defp emit_no_advance_state_def(:anything, cs, %{collect: :before, emit: emit, state: ns}), do:
    quote do
      def scan(unquote(cs), [head|_]=input, col, part, tokens) do
        {nc, nts} = add_token_and_col(tokens, col, [head|part], unquote(emit))
        scan(unquote(ns), input, nc, [], nts)
      end
    end
  defp emit_no_advance_state_def(grapheme, cs, %{collect: :before, emit: emit, state: ns}), do:
    quote do
      def scan(unquote(cs), [unquote(grapheme)|_]=input, col, part, tokens) do
        {nc, nts} = add_token_and_col(tokens, col, [unquote(grapheme)|part], unquote(emit))
        scan(unquote(ns), input, nc, [], nts)
      end
    end
  defp emit_no_advance_state_def(:anything, cs, %{collect: nil, emit: emit, state: ns}), do:
    quote do
      def scan(unquote(cs), input, col, part, tokens) do
        {nc, nts} = add_token_and_col(tokens, col, part, unquote(emit))
        scan(unquote(ns), input, nc, [], nts)
      end
    end
  defp emit_no_advance_state_def(grapheme, cs, %{collect: nil, emit: emit, state: ns}), do:
    quote do
      def scan(unquote(cs), [unquote(grapheme)|_]=input, col, part, tokens) do
        {nc, nts} = add_token_and_col(tokens, col, part, unquote(emit))
        scan(unquote(ns), input, nc, [], nts)
      end
    end
  defp emit_no_advance_state_def(:anything, cs, %{emit: emit, state: ns}), do:
    quote do
      def scan(unquote(cs), [head|_]=input, col, part, tokens) do
        {nc, nts} = add_token_and_col(tokens, col, part, unquote(emit))
        scan(unquote(ns), input, nc, [head], nts)
      end
    end
  defp emit_no_advance_state_def(grapheme, cs, %{emit: emit, state: ns}), do:
    quote do
      def scan(unquote(cs), [unquote(grapheme)|_]=input, col, part, tokens) do
        {nc, nts} = add_token_and_col(tokens, col, part, unquote(emit))
        scan(unquote(ns), input, nc, [unquote(grapheme)], nts)
      end
    end
    
  defp emit_advance_any_state_def(current_state, params)
  defp emit_advance_any_state_def(cs, %{collect: false, emit: nil}=params) do
    ns = Map.get(params, :state) || cs
    quote do
      def scan(unquote(cs), [head|rest], col, part, tokens), do: scan(unquote(ns), rest, col, part, tokens)
    end
  end
  defp emit_advance_any_state_def(cs, %{emit: nil}=params) do
    ns = Map.get(params, :state) || cs
    quote do
      def scan(unquote(cs), [head|rest], col, part, tokens), do: scan(unquote(ns), rest, col, [head|part], tokens)
    end
  end
  defp emit_advance_any_state_def(cs, %{collect: :before, emit: emit}=params) do
    ns = Map.get(params, :state) || cs
    quote do
      def scan(unquote(cs), [head|rest], col, part, tokens) do
        {nc, nts} = add_token_and_col(tokens, col, [head|part], unquote(emit))
        scan(unquote(ns), rest, nc, [], nts)
      end
    end
  end
  defp emit_advance_any_state_def(cs, %{collect: false, emit: emit}=params) do
    ns = Map.get(params, :state) || cs
    quote do
      def scan(unquote(cs), [_|rest], col, part, tokens) do
        {nc, nts} = add_token_and_col(tokens, col, part, unquote(emit))
        scan(unquote(ns), rest, nc, [], nts)
      end
    end
  end
  defp emit_advance_any_state_def(cs, %{emit: emit}=params) do
    ns = Map.get(params, :state) || cs
    quote do
      def scan(unquote(cs), [head|rest], col, part, tokens) do
        {nc, nts} = add_token_and_col(tokens, col, part, unquote(emit))
        scan(unquote(ns), rest, nc, [head], nts)
      end
    end
  end

  defp emit_advance_on_state_def(grapheme, current_state, params)
  defp emit_advance_on_state_def(g, cs, %{collect: false, emit: nil}=params) do
    ns = Map.get(params, :state) || cs
    quote do
      def scan(unquote(cs), [unquote(g)|rest], col, part, tokens), do:
        scan(unquote(ns), rest, col, part, tokens)
    end
  end
  defp emit_advance_on_state_def(g, cs, %{collect: true, emit: nil}=params) do
    ns = Map.get(params, :state) || cs
    quote do
      def scan(unquote(cs), [unquote(g)|rest], col, part, tokens), do:
        scan(unquote(ns), rest, col, [unquote(g)|part], tokens)
    end
  end
  defp emit_advance_on_state_def(g, cs, %{collect: :before, emit: emit}=params) do
    ns = Map.get(params, :state) || cs
    quote do
      def scan(unquote(cs), [unquote(g)|rest], col, part, tokens) do
        {nc, nts} = add_token_and_col(tokens, col, [unquote(g)|part], unquote(emit))
        scan(unquote(ns), rest, nc, [], nts)
      end
    end
  end
  defp emit_advance_on_state_def(g, cs, %{collect: false, emit: emit}=params) do
    ns = Map.get(params, :state) || cs
    quote do
      def scan(unquote(cs), [unquote(g)|rest], col, part, tokens) do
        {nc, nts} = add_token_and_col(tokens, col, part, unquote(emit))
        scan(unquote(ns), rest, nc, [], nts)
      end
    end
  end
  defp emit_advance_on_state_def(g, cs, %{emit: emit}=params) do
    ns = Map.get(params, :state) || cs
    quote do
      def scan(unquote(cs), [unquote(g)|rest], col, part, tokens) do
        {nc, nts} = add_token_and_col(tokens, col, part, unquote(emit))
        scan(unquote(ns), rest, nc, [unquote(g)], nts)
      end
    end
  end


  defp add_token(tokens, col, part, state) do
    string = partial |> IO.iodata_to_binary() |> String.reverse()
    [{state, string, col} | tokens]
  end
  defp add_token_and_col(tokens, col, part, state) do
    with [{_, string, _} | _] = new_tokens <- add_token(tokens, col, part, state) do
      {col + String.length(string), new_tokens}
    end
  end

  # def emit_scan_definition({:anything, current_state, params, nil}), do:
  #   emit_scan_def_on(current_state, (quote do: head), params)
  # def emit_scan_definition({:on, current_state, params, grapheme}), do:
  #   emit_scan_def_on(current_state, (quote do: unquote(grapheme)), params)


  # defp emit_scan_def_empty(current_state, params)
  # defp emit_scan_def_empty(current_state, %{state: state}=params) do
  #   if current_state == state do
  #     raise "Error loop in state #{inspect current_state} at EOI"
  #   end
  #   if state == nil || state == :halt do
  #     emit_scan_def_empty_return(current_state, params)
  #   else
  #     emit_scan_def_empty_new_state(current_state, params)
  #   end
  # end

  # defp emit_scan_def_empty_return(current_state, params)
  # defp emit_scan_def_empty_return(current_state, %{emit: false}) do
  #   quote do
  #     def scan({unquote(current_state), [], col, partial, tokens}), do: tokens |> Enum.reverse
  #   end
  # end
  # defp emit_scan_def_empty_return(current_state, %{emit: emit}) do
  #   quote do
  #     def scan({unquote(current_state), [], col, partial, tokens}), do:
  #       [{unquote(emit), string_from(partial), col} | tokens] |> Enum.reverse
  #   end
  # end

  # defp emit_scan_def_empty_new_state(current_state, params) do
  #   quote do
  #     def scan({unquote(current_state), [], col, partial, tokens}), do:
  #       scan({unquote(params.new_state), [], col, partial, tokens})
  #   end
  # end


  # defp emit_scan_def_on(current_state, first_element, params)
  # defp emit_scan_def_on(current_state, first_element, %{advance: false}=params), do:
  #   emit_scan_def_no_advance(current_state, params)
  # defp emit_scan_def_on(current_state, first_element, %{collect: false}=params), do:
  #   emit_scan_def_no_collect(current_state, first_element, params)


  # defp emit_scan_def_no_advance(current_state, %{state: state} = params) do
  #   if current_state == ( state || current_state ) do
  #     raise "Error loop in state #{inspect current_state} must not use advance: false without changing state"
  #   end
  #   if state == :halt do
  #     emit_scan_def_return(current_state, params)
  #   else
  #     emit_scan_def_continue(current_state, params)
  #   end
  # end

  # defp emit_scan_def_return(current_state, params)
  # defp emit_scan_def_return(current_state, %{emit: false}) do
  #   quote do
  #     def scan({unquote(current_state), _, _, _, tokens}), do: tokens |> Enum.reverse
  #   end
  # end
  # defp emit_scan_def_return(current_state, %{collect: false, emit: emit}) do
  #   quote do
  #     def scan({unquote(current_state), _, col, partial, tokens}), do:
  #       [{unquote(emit), string_from(partial), col} | tokens] |> Enum.reverse
  #   end
  # end

  # defp emit_scan_def_no_collect(current_state, params)
  # defp emit_scan_def_no_collect(current_state, 
  #   # quote do
  #   #   def scan({unquote(current_state), input, col, partial,
    # end

  # end


    # quote do
    #   def scan({ unquote(current_state), [], _, _, tokens}), do: Enum.revers(tokens) 
    # end
  # end
  # def emit_scan_definition({:empty, current_state, _emit_state, nil}) do
    # quote do
    #   def scan({unquote(current_state), [], col, partial, tokens }), do: emit_return(unquote(current_state), col, partial, tokens)
    # end
  # end
  # def emit_scan_definition({:on, current_state, %{state: new_state}, grapheme}) do
    # quote do
    #   def scan({unquote(current_state), [unquote(grapheme)|rest], col, partial, tokens}), do: scan({unquote(new_state), rest, col, [unquote(grapheme)|partial], tokens})
    # end
  # end

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
