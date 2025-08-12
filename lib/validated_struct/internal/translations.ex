defmodule ValidatedStruct.Internal.Translations do
  @moduledoc """
  This files contains the translations of the data structures from
  validated struct to validixir and vice versa.
  """

  alias ValidatedStruct.Error
  alias ValidatedStruct.Failure
  alias ValidatedStruct.Internal.ValidixirWrapper

  defimpl ValidixirWrapper.Translateable, for: Error do
    def translate(v) do
      map = Map.from_struct(v)
      struct(Validixir.Error, map)
    end
  end

  defimpl ValidixirWrapper.Translateable, for: Validixir.Error do
    def translate(v) do
      map = Map.from_struct(v)
      struct(Error, map)
    end
  end

  defimpl ValidixirWrapper.Translateable, for: Failure do
    def translate(data) do
      data = %Failure{data | errors: Enum.map(data.errors, &ValidixirWrapper.Translateable.translate/1)}
      struct(Validixir.Failure, Map.from_struct(data))
    end
  end

  defimpl ValidixirWrapper.Translateable, for: Validixir.Failure do
    def translate(data) do
      errors = Enum.map(data.errors, &ValidixirWrapper.Translateable.translate/1)
      data = %Validixir.Failure{data | errors: errors}
      struct(Failure, Map.from_struct(data))
    end
  end
end
