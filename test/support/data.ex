defmodule ValidatedStructTest.Data do
  alias __MODULE__

  defmodule Inner do
    alias __MODULE__

    use ValidatedStruct

    @validated_type(non_empty_string_t :: String.t(),
      validation: &ValidatedStructTest.Data.validate_non_empty_string/1
    )

    validatedstruct struct_validation: &Data.Inner.validate_not_equal/1 do
      field(:bla, binary())
      field(:blub, non_empty_string_t())
    end

    def validate_not_equal(%Inner{bla: bla, blub: blub} = inner) do
      if bla != blub do
        {:ok, inner}
      else
        ValidatedStruct.failure_from_error(inner, :should_not_be_equal, __MODULE__)
      end
    end
  end

  @type b :: binary()

  use ValidatedStruct

  validatedstruct do
    field(:hello, b(), default: "123")
    field(:bye, integer())
    field(:world, Inner.t())
  end

  def test(one: one, two: two) do
    {one, two}
  end

  @spec validate_non_empty_string(any()) :: ValidatedStruct.validation_result_t(String.t())
  def validate_non_empty_string(str, message \\ :string_must_not_be_empty) do
    with {:ok, _} <- ValidatedStruct.Validations.binary(str) do
      case str do
        "" -> ValidatedStruct.failure_from_error("", message, ValidatedStructTest.Data)
        e -> ValidatedStruct.success(e)
      end
    end
  end
end
