defmodule Accu do
  
  defmacro __using__(_options) do
    quote do
      import unquote(__MODULE__) 
      Module.register_attribute __MODULE__, :_accu, accumulate: true
      @before_compile unquote(__MODULE__)
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      def show_accu() do
        @_accu
      end
    end
  end

  defmacro add_info(ele) do
    quote bind_quoted: [ele: ele] do
      @_accu ele
    end
  end
end
