defmodule ValidatedStruct.Internal.ValidixirWrapper do
  @moduledoc """
  This module offers tooling to seamlessly switch between
  the validixir and validated struct contexts
  """
  alias ValidatedStruct.Internal.ValidixirWrapper.Translateable

  def apply_translated(foo, validation_result) do
    translate(validation_result)
    |> foo.()
    |> translate()
  end

  def apply_translated(foo, validation_result_1, validation_result_2) do
    v1 = translate(validation_result_1)
    v2 = translate(validation_result_2)

    foo.(v1, v2)
    |> translate()
  end

  def with_translation(foo) do
    &apply_translated(foo, &1)
  end

  def translate({:error, f}) do
    {:error, Translateable.translate(f)}
  end

  def translate(v) do
    Translateable.translate(v)
  end

  defprotocol Translateable do
    @fallback_to_any true
    def translate(v)
  end

  defimpl Translateable, for: Any do
    def translate(v), do: v
  end
end
