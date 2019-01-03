defmodule Md0.Scanner.RgxMacros do

  defmacro __using__(_options) do
    quote do
      import unquote(__MODULE__)
      Module.put_attribute __MODULE__, :_defined_tokens, [] 
      Module.put_attribute __MODULE__, :_defined_start_tokens, [] 
    end
  end
  

  defmacro defstarttoken(name, regex_str) do
    quote bind_quoted: [name: name, regex_str: regex_str] do
      regex = "\\A(#{regex_str})(.*)\\z" 
      already_defined = Module.get_attribute(__MODULE__, :_defined_start_tokens)
      Module.put_attribute __MODULE__,
        :_defined_start_tokens, 
        [{name, Regex.compile!(regex, "u")} | already_defined]
    end
  end


  defmacro deftoken(name, regex_str) do
    quote bind_quoted: [name: name, regex_str: regex_str] do
      regex = "\\A(#{regex_str})(.*)\\z" 
      already_defined = Module.get_attribute(__MODULE__, :_defined_tokens)
      Module.put_attribute __MODULE__,
        :_defined_tokens, 
        [{name, Regex.compile!(regex, "u")} | already_defined]
    end
  end

end
