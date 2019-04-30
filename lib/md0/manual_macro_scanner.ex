defmodule Md0.ManualMacroScanner do

  use Md0.Scanner.ManualMacro


  state :start do
    empty :halt# allows input do end here and emit all tokens scanned so far
    on " ", :indent
    on "*", :li
    on "`", :back
    anything :any
  end

  state :any do
    empty :halt, emit: :any # and returns implicitly
    on " ", :ws, emit: :any # " " is collected **after** emission
    on "*", :star, emit: :any
    on "`", :back, emit: :any
    anything :any # Maybe a good idea to add the `anything current_state` transition as default transiton for a state
  end

  state :back do
    empty :halt, emit: :back
    on " ", :ws, emit: :back
    on "`", :back
    on "*", :star, emit: :back
    anything :any, emit: :back
  end

  state :indent do
    empty :halt, emit: :indent
    on " ", :indent
    on "*", :li, emit: :indent
    on "`", :back, emit: :indent
    anything :any, emit: :indent
  end
  # Looking at the three above states the following syntax seems like a big gain
  # e.g.
  #       state :back do
  #         with_default emit: :back do
  #           empty :halt
  #           on " ", :ws
  #           on "*", :star
  #           anything :any
  #         end
  #         consume "`"               # same as on "`" <current state>
  #       end

  state :li do
    empty :halt, emit: :star
    on " ", :rest, emit: :li, collect: :before # this means the " " is part of the emitted token and not the next one
    on "*", :star
    on "`", :back, emit: :star
    anything :any, emit: :star
  end

  state :rest do
    empty :halt
    on " ", :ws
    on "*", :star
    on "`", :back
    anything :any
  end

  state :star do
    empty :halt, emit: :star
    on " ", :ws, emit: :star
    on "`", :back, emit: :star
    on "*", :star
    anything :any, emit: :star
  end

  state :ws do
    empty :halt, emit: :ws
    on " ", :ws
    on "`", :back, emit: :ws
    on "*", :li, emit: :ws
    anything :any, emit: :ws
  end
end
