defmodule ValidatedStruct.GeneratorTestStructs do
  defmodule StringStruct do
    use ValidatedStruct

    validatedstruct do
      field(:v, String.t())
    end
  end

  defmodule EmptyStruct do
    use ValidatedStruct

    validatedstruct do
    end
  end

  defmodule BinaryStruct do
    use ValidatedStruct

    validatedstruct do
      field(:v, binary())
    end
  end

  defmodule IntegerStruct do
    use ValidatedStruct

    validatedstruct do
      field(:v, integer())
    end
  end

  defmodule StructStruct do
    use ValidatedStruct

    validatedstruct do
      field(:v, IntegerStruct.t())
    end
  end

  defmodule AnyAtomStruct do
    use ValidatedStruct

    validatedstruct do
      field(:v, atom())
    end
  end

  defmodule AnyStruct do
    use ValidatedStruct

    validatedstruct do
      field(:v, atom())
    end
  end

  defmodule MapAnyStruct do
    use ValidatedStruct

    validatedstruct do
      field(:v, map())
    end
  end

  defmodule EmptyMapStruct do
    use ValidatedStruct

    validatedstruct do
      field(:v, %{})
    end
  end

  defmodule TupleAnyStruct do
    use ValidatedStruct

    validatedstruct do
      field(:v, tuple())
    end
  end

  defmodule PidStruct do
    use ValidatedStruct

    validatedstruct do
      field(:v, pid())
    end
  end

  defmodule ReferenceStruct do
    use ValidatedStruct

    validatedstruct do
      field(:v, reference())
    end
  end

  defmodule PortStruct do
    use ValidatedStruct

    validatedstruct do
      field(:v, port())
    end
  end

  defmodule TupleStruct do
    use ValidatedStruct

    validatedstruct do
      field(:v, {binary(), integer(), integer()})
    end
  end

  defmodule UnionStruct do
    use ValidatedStruct

    validatedstruct do
      field(:v, binary() | integer())
    end
  end

  defmodule PosIntegerStruct do
    use ValidatedStruct

    validatedstruct do
      field(:v, pos_integer())
    end
  end

  defmodule NonNegIntegerStruct do
    use ValidatedStruct

    validatedstruct do
      field(:v, non_neg_integer())
    end
  end

  defmodule NegIntegerStruct do
    use ValidatedStruct

    validatedstruct do
      field(:v, neg_integer())
    end
  end

  defmodule BooleanStruct do
    use ValidatedStruct

    validatedstruct do
      field(:v, boolean())
    end
  end

  defmodule ListStruct do
    use ValidatedStruct

    validatedstruct do
      field(:v, list(integer()))
    end
  end

  defmodule MapStruct do
    use ValidatedStruct

    validatedstruct do
      field(:v, %{required(:foo) => String.t(), optional(:bar) => integer()})
    end
  end

  defmodule EmptyListStruct do
    use ValidatedStruct

    validatedstruct do
      field(:v, [])
    end
  end

  defmodule NonemptyListStruct do
    use ValidatedStruct

    validatedstruct do
      field(:v, nonempty_list(integer()))
    end
  end

  defmodule AtomStruct do
    use ValidatedStruct

    validatedstruct do
      field(:v, :foo)
    end
  end

  defmodule LiteralBooleanStruct do
    use ValidatedStruct

    validatedstruct do
      field(:v, true)
    end
  end

  defmodule LiteralIntegerStruct do
    use ValidatedStruct

    validatedstruct do
      field(:v, 1)
    end
  end

  defmodule FunStruct do
    use ValidatedStruct

    validatedstruct do
      field(:v, fun())
    end
  end

  defmodule RangeStruct do
    use ValidatedStruct

    validatedstruct do
      field(:v, 1..5)
    end
  end

  defmodule NilStruct do
    use ValidatedStruct

    validatedstruct do
      field(:v, nil)
    end
  end

  defmodule ComplexStruct do
    use ValidatedStruct

    validatedstruct do
      field(:numbers, nonempty_list(IntegerStruct.t()))
      field(:a_map, %{required(:foo) => BooleanStruct.t()})
    end
  end
end
