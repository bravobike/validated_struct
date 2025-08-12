defmodule ValidatedStruct.TypeExporter do
  @moduledoc """
  This module wraps `TypeResolver.TypeExporter` and adds the
  macro for validated types.

  ## Usage:

      defmodule Foo do
        use ValidatedStruct.TypeExporter 
      
        @validated_type(non_empty_string_t :: String.t(), validation: &Common.Validation.validate_non_empty_string/1)
      end

  Validated types will, when used in validated structs, always be validated using
  the provided validation.
  """

  defmacro __using__(_opts) do
    quote do
      import Kernel, except: [@: 1]
      import ValidatedStruct.TypeExporter

      Module.register_attribute(__MODULE__, :__validations, accumulate: true)

      use TypeResolver.TypeExporter

      @before_compile {ValidatedStruct.TypeExporter, :provide_validations}
    end
  end

  @doc false
  defmacro @{:validated_type, _, [type, [validation: foo]]} do
    type_name = get_type_name(type)

    quote do
      @__validations {unquote(type_name), unquote(foo |> Macro.expand(__ENV__))}
      @type unquote(type)
    end
  end

  defmacro @other do
    quote do
      Kernel.@(unquote(other))
    end
  end

  defmacro provide_validations(_) do
    quote do
      def __validation_for(k) do
        @__validations |> Keyword.get(k)
      end
    end
  end

  defp get_type_name({:"::", _, [{name, _, _}, _]}), do: name
end
