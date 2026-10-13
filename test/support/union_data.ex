defmodule ValidatedStructTest.UnionData do
  @moduledoc false

  defmodule A do
    use ValidatedStruct

    validatedstruct do
      field(:id, integer())
    end
  end

  defmodule B do
    use ValidatedStruct

    validatedstruct do
      field(:id, integer())
    end
  end

  defmodule C do
    use ValidatedStruct

    validatedstruct do
      field(:id, integer())
    end
  end

  defmodule LeftNested do
    use ValidatedStruct

    validatedstruct do
      field(:event, (A.t() | B.t()) | C.t())
    end
  end

  defmodule RightNested do
    use ValidatedStruct

    validatedstruct do
      field(:event, A.t() | B.t() | C.t())
    end
  end

  defmodule Probes do
    use ValidatedStruct

    @validated_type(below_10_t :: integer(),
      validation: &ValidatedStructTest.UnionData.below_10/1
    )

    @validated_type(below_100_t :: integer(),
      validation: &ValidatedStructTest.UnionData.below_100/1
    )

    @validated_type(any_integer_t :: integer(),
      validation: &ValidatedStructTest.UnionData.any_integer/1
    )
  end

  defmodule ProbeLeftNested do
    use ValidatedStruct

    validatedstruct do
      field(:value, (Probes.below_10_t() | Probes.below_100_t()) | Probes.any_integer_t())
    end
  end

  defmodule ProbeRightNested do
    use ValidatedStruct

    validatedstruct do
      field(:value, Probes.below_10_t() | Probes.below_100_t() | Probes.any_integer_t())
    end
  end

  def below_10(c), do: probe(:below_10, c, is_integer(c) and c < 10)
  def below_100(c), do: probe(:below_100, c, is_integer(c) and c < 100)
  def any_integer(c), do: probe(:any_integer, c, is_integer(c))

  defp probe(name, c, matches?) do
    send(self(), {:probed, name})

    if matches? do
      ValidatedStruct.success({name, c})
    else
      ValidatedStruct.failure_from_error(c, {:rejected_by, name}, __MODULE__)
    end
  end
end
