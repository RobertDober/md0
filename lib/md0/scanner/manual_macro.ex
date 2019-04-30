defmodule Md0.Scanner.ManualMacro do

  defmacro __before_compile__(env) do
    definitions = 
    Module.get_attribute(env.module, :_transitions) 
    |> Enum.reverse
    |> Enum.map(&emit_scan_definition/1)

    if System.get_env("DEBUG_MACROS") do
      definitions
      |> Macro.to_string
      |> IO.puts
    end
    quote do
      def scan(nil, nil, 0, nil, nil), do: []
      defoverridable scan: 5
      unquote_splicing(definitions)
    end
  end

  defmacro __using__(_options) do
    quote do
      @before_compile unquote(__MODULE__)
      import unquote(__MODULE__)
      def scan_document(doc) do
        doc
        |> String.split(~r{\r\n?|\n})
        |> Enum.zip(Stream.iterate(1, &(&1 + 1)))
        |> Enum.flat_map(&scan_line/1)
      end

      def scan_line({line, lnb}), do:
        scan(:start, String.graphemes(line), {lnb, 1}, [], [])
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


  defmacro on(grapheme, state, params \\ []), do: add_transition(grapheme, state, params)
  defmacro empty(state, params \\ []), do: add_transition(:empty, state, params)
  defmacro anything(state, params \\ []), do: add_transition(:anything, state, params)

  @default_params %{
    advance: true,
    collect: true,
    emit: nil,
    state: nil
  }

  defp add_transition(trigger, state, params)
  defp add_transition(:empty, state, _params) when is_list(state) do
    _add_transition(:empty, Keyword.put_new(state, :state, :halt))
  end
  defp add_transition(trigger, state, _params) when is_list(state) do
    _add_transition(trigger, state)
  end
  defp add_transition(trigger, state, params) do
    _add_transition(trigger, Keyword.put(params, :state, state))
  end

  defp _add_transition(trigger, params) do
    params =
    if is_list(params) do
      params|>Enum.into(@default_params)
    else
      params
    end

    params = 
    if Map.get(params, :emit) do
      Map.put_new(params, :collect, :before)
    else
      params
    end

    quote do
      current_state = Module.get_attribute(__MODULE__, :_current_state)
      if current_state == nil do
        raise "Must not call `#{unquote(macro_name_of_trigger(trigger))}` macro outside of state macro"
      end
      @_transitions {unquote(trigger), current_state, unquote(params|>Macro.escape)}
    end
  end

  defp macro_name_of_trigger(trigger)
  defp macro_name_of_trigger(trigger) when is_binary(trigger) do
    "on"
  end
  defp macro_name_of_trigger(trigger), do: trigger


  def add_token(tokens, {lnb, col}, part, state) do
    string = part |> IO.iodata_to_binary() |> String.reverse()
    [{state, string, lnb, col} | tokens]
  end

  def add_token_and_col(tokens, {lnb, col}, part, state) do
    with [{_, string, _, _} | _] = new_tokens <- add_token(tokens, {lnb, col}, part, state) do
      {col + String.length(string), new_tokens}
    end
  end

  defp emit_scan_definition(transition)
  defp emit_scan_definition({:empty, current_state, params}), do:
    emit_empty_state_def(current_state, params)
  defp emit_scan_definition({trigger, current_state, %{state: :halt} = params}), do:
    emit_halt_state_def(trigger, current_state, params)
  defp emit_scan_definition({trigger, current_state, %{advance: false} = params}), do:
    emit_no_advance_state_def(trigger, current_state, params)
  defp emit_scan_definition({:anything, current_state, params}), do:
    emit_advance_any_state_def(current_state, params)
  defp emit_scan_definition({grapheme, current_state, params}), do:
    emit_advance_on_state_def(grapheme, current_state, params)


  defp emit_empty_state_def(current_state, params)
  defp emit_empty_state_def(cs, %{emit: nil, state: :halt}) do
    quote do
      def scan(unquote(cs), [], _, _, tokens), do: Enum.reverse(tokens)
    end
  end
  defp emit_empty_state_def(cs, %{emit: emit, state: :halt}) do
    quote do
      def scan(unquote(cs), [], lnb_col, part, tokens), do: Enum.reverse(add_token(tokens, lnb_col, part, unquote(emit)))
    end
  end
  defp emit_empty_state_def(cs, %{emit: nil, state: ns}) do
    if (ns || cs) == cs do
      raise "Illegal loop at EOI with state: #{cs}"
    else
      quote do
        def scan(unquote(cs), [], lnb_col, part, tokens), do: scan(unquote(ns), [], lnb_col, part, tokens)
      end
    end
  end
  defp emit_empty_state_def(cs, %{emit: emit, state: ns}) do
    if (ns || cs) == cs do
      raise "Illegal loop at EOI with state: #{cs}"
    else
      quote do
        def scan(unquote(cs), [], {lnb, col}, part, tokens) do
          {nc, nts} = add_token_and_col(tokens, {lnb, col}, part, unquote(emit))
          scan(unquote(ns), [], {lnb, nc}, [], nts)
        end
      end
    end
  end

  defp emit_halt_state_def(trigger, current_state, params)
  defp emit_halt_state_def(_, cs, %{collect: false, emit: nil}) do
    quote do
      def scan(unquote(cs), _, _, _, tokens), do: Enum.reverse(tokens)
    end
  end
  defp emit_halt_state_def(_, cs, %{collect: false, emit: emit}) do
    quote do
      def scan(unquote(cs), _, lnb_col, parts, tokens), do: Enum.reverse(add_token(tokens, lnb_col, parts, unquote(emit)))
    end
  end
  defp emit_halt_state_def(:anything, cs, %{collect: :before, emit: emit}) do
    quote do
      def scan(unquote(cs), [h|_], lnb_col, parts, tokens), do:
        Enum.reverse(add_token(tokens, lnb_col, [h|parts], unquote(emit)))
    end
  end
  defp emit_halt_state_def(grapheme, cs, %{collect: :before, emit: emit}) do
    graphemes = String.graphemes(grapheme)
    quote do
      def scan(unquote(cs), [unquote_splicing(graphemes)|_], lnb_col, parts, tokens) do
        Enum.reverse(add_token(tokens, lnb_col, [unquote_splicing(Enum.reverse(graphemes))|parts], unquote(emit |> IO.inspect)))
      end
    end
  end
  # We assume collect to be false unless it was :before
  defp emit_halt_state_def(grapheme, cs, params) do
    emit_halt_state_def(grapheme, cs, Map.put(params, :collect, :before))
  end
    
  defp emit_no_advance_state_def(trigger, current_state, params)
  defp emit_no_advance_state_def(_, cs, %{state: nil}), do: raise "Error looping with no advance in state: #{cs}"
  defp emit_no_advance_state_def(_, cs, %{state: ns}) when ns == cs do
    raise "Error looping with no advance in state: #{cs}"
  end
  defp emit_no_advance_state_def(:anything, cs, %{collect: false, emit: nil, state: ns}) do
    quote do
      def scan(unquote(cs), input, lnb_col, part, tokens), do: scan(unquote(ns), input, lnb_col, part, tokens)
    end
  end
  defp emit_no_advance_state_def(grapheme, cs, %{collect: false, emit: nil, state: ns}) do
    graphemes = String.graphemes(grapheme)
    quote do
      def scan(unquote(cs), [unquote_splicing(graphemes)|_]=input, lnb_col, part, tokens), do: scan(unquote(ns), input, lnb_col, part, tokens)
    end
  end
  defp emit_no_advance_state_def(:anything, cs, %{emit: nil, state: ns}) do
    quote do
      def scan(unquote(cs), [head|_]=input, lnb_col, part, tokens), do: scan(unquote(ns), input, lnb_col, [head|part], tokens)
    end
  end
  defp emit_no_advance_state_def(grapheme, cs, %{emit: nil, state: ns}) do
    graphemes = String.graphemes(grapheme)
    quote do
      def scan(unquote(cs), [unquote_splicing(graphemes)|_]=input, lnb_col, part, tokens), do: scan(unquote(ns), input, lnb_col, [unquote_splicing(Enum.reverse(graphemes))|part], tokens)
    end
  end
  defp emit_no_advance_state_def(:anything, cs, %{collect: :before, emit: emit, state: ns}) do
    quote do
      def scan(unquote(cs), [head|_]=input, {lnb, col}, part, tokens) do
        {nc, nts} = add_token_and_col(tokens, {lnb, col}, [head|part], unquote(emit))
        scan(unquote(ns), input, {lnb, nc}, [], nts)
      end
    end
  end
  defp emit_no_advance_state_def(grapheme, cs, %{collect: :before, emit: emit, state: ns}) do
    graphemes = String.graphemes(grapheme)
    quote do
      def scan(unquote(cs), [unquote_splicing(graphemes)|_]=input, {lnb, col}, part, tokens) do
        {nc, nts} = add_token_and_col(tokens, {lnb, col}, [unquote_splicing(Enum.reverse(graphemes))|part], unquote(emit))
        scan(unquote(ns), input, {lnb, nc}, [], nts)
      end
    end
  end
  defp emit_no_advance_state_def(:anything, cs, %{collect: nil, emit: emit, state: ns}) do
    quote do
      def scan(unquote(cs), input, {lnb, col}, part, tokens) do
        {nc, nts} = add_token_and_col(tokens, {lnb, col}, part, unquote(emit))
        scan(unquote(ns), input, {lnb, nc}, [], nts)
      end
    end
  end
  defp emit_no_advance_state_def(grapheme, cs, %{collect: nil, emit: emit, state: ns}) do
    graphemes = String.graphemes(grapheme)
    quote do
      def scan(unquote(cs), [unquote_splicing(graphemes)|_]=input, {lnb, col}, part, tokens) do
        {nc, nts} = add_token_and_col(tokens, {lnb, col}, part, unquote(emit))
        scan(unquote(ns), input, {lnb, nc}, [], nts)
      end
    end
  end
  defp emit_no_advance_state_def(:anything, cs, %{emit: emit, state: ns}) do
    quote do
      def scan(unquote(cs), [head|_]=input, {lnb, col}, part, tokens) do
        {nc, nts} = add_token_and_col(tokens, {lnb, col}, part, unquote(emit))
        scan(unquote(ns), input, {lnb, nc}, [head], nts)
      end
    end
  end
  defp emit_no_advance_state_def(grapheme, cs, %{emit: emit, state: ns}) do
    graphemes = String.graphemes(grapheme)
    quote do
      def scan(unquote(cs), [unquote_splicing(graphemes)|_]=input, {lnb, col}, part, tokens) do
        {nc, nts} = add_token_and_col(tokens, {lnb, col}, part, unquote(emit))
        scan(unquote(ns), input, {lnb, nc}, [unquote_splicing(Enum.reverse(graphemes))], nts)
      end
    end
  end
    
  defp emit_advance_any_state_def(current_state, params)
  defp emit_advance_any_state_def(cs, %{collect: false, emit: nil}=params) do
    ns = Map.get(params, :state) || cs
    quote do
      def scan(unquote(cs), [head|rest], lnb_col, part, tokens), do: scan(unquote(ns), rest, lnb_col, part, tokens)
    end
  end
  defp emit_advance_any_state_def(cs, %{emit: nil}=params) do
    ns = Map.get(params, :state) || cs
    quote do
      def scan(unquote(cs), [head|rest], lnb_col, part, tokens), do: scan(unquote(ns), rest, lnb_col, [head|part], tokens)
    end
  end
  defp emit_advance_any_state_def(cs, %{collect: :before, emit: emit}=params) do
    ns = Map.get(params, :state) || cs
    quote do
      def scan(unquote(cs), [head|rest], {lnb, col}, part, tokens) do
        {nc, nts} = add_token_and_col(tokens, {lnb, col}, [head|part], unquote(emit))
        scan(unquote(ns), rest, {lnb, nc}, [], nts)
      end
    end
  end
  defp emit_advance_any_state_def(cs, %{collect: false, emit: emit}=params) do
    ns = Map.get(params, :state) || cs
    quote do
      def scan(unquote(cs), [_|rest], {lnb, col}, part, tokens) do
        {nc, nts} = add_token_and_col(tokens, {lnb, col}, part, unquote(emit))
        scan(unquote(ns), rest, {lnb, nc}, [], nts)
      end
    end
  end
  defp emit_advance_any_state_def(cs, %{emit: emit}=params) do
    ns = Map.get(params, :state) || cs
    quote do
      def scan(unquote(cs), [head|rest], {lnb, col}, part, tokens) do
        {nc, nts} = add_token_and_col(tokens, {lnb, col}, part, unquote(emit))
        scan(unquote(ns), rest, {lnb, nc}, [head], nts)
      end
    end
  end

  defp emit_advance_on_state_def(grapheme, current_state, params)
  defp emit_advance_on_state_def(g, cs, %{collect: false, emit: nil}=params) do
    graphemes = String.graphemes(g)
    ns = Map.get(params, :state) || cs
    quote do
      def scan(unquote(cs), [unquote_splicing(graphemes)|rest], lnb_col, part, tokens), do:
        scan(unquote(ns), rest, lnb_col, part, tokens)
    end
  end
  defp emit_advance_on_state_def(g, cs, %{collect: true, emit: nil}=params) do
    graphemes = String.graphemes(g)
    ns = Map.get(params, :state) || cs
    quote do
      def scan(unquote(cs), [unquote_splicing(graphemes)|rest], lnb_col, part, tokens), do:
        scan(unquote(ns), rest, lnb_col, [unquote_splicing(Enum.reverse(graphemes))|part], tokens)
    end
  end
  defp emit_advance_on_state_def(g, cs, %{collect: :before, emit: emit}=params) do
    graphemes = String.graphemes(g)
    ns = Map.get(params, :state) || cs
    quote do
      def scan(unquote(cs), [unquote_splicing(graphemes)|rest], {lnb, col}, part, tokens) do
        {nc, nts} = add_token_and_col(tokens, {lnb, col}, [unquote_splicing(Enum.reverse(graphemes))|part], unquote(emit))
        scan(unquote(ns), rest, {lnb, nc}, [], nts)
      end
    end
  end
  defp emit_advance_on_state_def(g, cs, %{collect: false, emit: emit}=params) do
    graphemes = String.graphemes(g)
    ns = Map.get(params, :state) || cs
    quote do
      def scan(unquote(cs), [unquote_splicing(graphemes)|rest], {lnb, col}, part, tokens) do
        {nc, nts} = add_token_and_col(tokens, {lnb, col}, part, unquote(emit))
        scan(unquote(ns), rest, {lnb, nc}, [], nts)
      end
    end
  end
  defp emit_advance_on_state_def(g, cs, %{emit: emit}=params) do
    graphemes = String.graphemes(g)
    ns = Map.get(params, :state) || cs
    quote do
      def scan(unquote(cs), [unquote_splicing(graphemes)|rest], {lnb, col}, part, tokens) do
        {nc, nts} = add_token_and_col(tokens, {lnb, col}, part, unquote(emit))
        scan(unquote(ns), rest, {lnb, nc}, [unquote_splicing(Enum.reverse(graphemes))], nts)
      end
    end
  end

end
