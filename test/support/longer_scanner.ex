defmodule Support.LongerScanner do
  use Md0.Scanner.ManualMacro

  state :start do
    on "##", :halt, emit: :h2
    on "#", :halt, emit: :h1
    on "ab", :halt, emit: :ab

    on "$>", :prefix, emit: :prefix, collect: :before
    anything :halt, emit: :else
  end

  state :prefix do
    empty :halt
    anything :halt, emit: :prefixed
  end

  def debug do
    IO.inspect @_transitions
  end

  # state :h1 do
  #   empty :halt, emit: :h1
  #   on "#", :h2
  #   anything :halt, emit: :else
  # end

  # state :h2 do
  #   empty :halt, emit: :h2
  #   anything :halt, emit: :else, collect: :before
  # end
end
