defmodule ValidatedStructTest.UnionValidationTest do
  use ExUnit.Case, async: true

  alias TypeResolver.Types
  alias ValidatedStruct.Error
  alias ValidatedStruct.Failure
  alias ValidatedStruct.Validations
  alias ValidatedStructTest.UnionData
  alias ValidatedStructTest.UnionData.A
  alias ValidatedStructTest.UnionData.B
  alias ValidatedStructTest.UnionData.C

  @a %Types.StructL{module: A}
  @b %Types.StructL{module: B}
  @c %Types.StructL{module: C}

  @below_10 %Types.NamedType{
    module: UnionData.Probes,
    name: :below_10_t,
    inner: %Types.IntegerT{}
  }
  @below_100 %Types.NamedType{
    module: UnionData.Probes,
    name: :below_100_t,
    inner: %Types.IntegerT{}
  }
  @any_integer %Types.NamedType{
    module: UnionData.Probes,
    name: :any_integer_t,
    inner: %Types.IntegerT{}
  }

  defp flat(x, y, z), do: [x, y, z]
  defp left_nested(x, y, z), do: [%Types.UnionT{inner: [x, y]}, z]
  defp right_nested(x, y, z), do: [x, %Types.UnionT{inner: [y, z]}]

  defp probed do
    receive do
      {:probed, name} -> [name | probed()]
    after
      0 -> []
    end
  end

  defp not_a_struct(wrapped_message) do
    Error.make(:nope, wrapped_message, ValidatedStruct)
  end

  for shape <- [:flat, :left_nested, :right_nested] do
    describe "union/2 with a #{shape} union" do
      test "accepts a value matching the first alternative" do
        types = unquote(shape)(@a, @b, @c)
        assert Validations.union(%A{id: 1}, types) == {:ok, %A{id: 1}}
      end

      test "accepts a value matching a middle alternative" do
        types = unquote(shape)(@a, @b, @c)
        assert Validations.union(%B{id: 1}, types) == {:ok, %B{id: 1}}
      end

      test "accepts a value matching the last alternative" do
        types = unquote(shape)(@a, @b, @c)
        assert Validations.union(%C{id: 1}, types) == {:ok, %C{id: 1}}
      end

      test "returns the result of the first matching alternative in declaration order" do
        types = unquote(shape)(@below_10, @below_100, @any_integer)

        assert Validations.union(5, types) == {:ok, {:below_10, 5}}
        assert Validations.union(50, types) == {:ok, {:below_100, 50}}
        assert Validations.union(500, types) == {:ok, {:any_integer, 500}}
      end

      test "does not validate the alternatives after the first matching one" do
        types = unquote(shape)(@below_10, @below_100, @any_integer)

        Validations.union(5, types)
        assert probed() == [:below_10]

        Validations.union(50, types)
        assert probed() == [:below_10, :below_100]

        Validations.union(500, types)
        assert probed() == [:below_10, :below_100, :any_integer]
      end

      test "validates every alternative once, in declaration order, if none matches" do
        types = unquote(shape)(@below_10, @below_100, @any_integer)

        assert {:error, %Failure{}} = Validations.union("x", types)
        assert probed() == [:below_10, :below_100, :any_integer]
      end
    end
  end

  describe "union/2 when no alternative matches" do
    test "reports one error per alternative of a flat union" do
      assert Validations.union(:nope, flat(@a, @b, @c)) ==
               Failure.make([
                 not_a_struct([:union_type, :not_of_type_struct]),
                 not_a_struct([:union_type, :not_of_type_struct]),
                 not_a_struct([:union_type, :not_of_type_struct])
               ])
    end

    test "wraps the errors of a left-nested union once per union level" do
      assert Validations.union(:nope, left_nested(@a, @b, @c)) ==
               Failure.make([
                 not_a_struct([:union_type, [:union_type, :not_of_type_struct]]),
                 not_a_struct([:union_type, [:union_type, :not_of_type_struct]]),
                 not_a_struct([:union_type, :not_of_type_struct])
               ])
    end

    test "wraps the errors of a right-nested union once per union level" do
      assert Validations.union(:nope, right_nested(@a, @b, @c)) ==
               Failure.make([
                 not_a_struct([:union_type, :not_of_type_struct]),
                 not_a_struct([:union_type, [:union_type, :not_of_type_struct]]),
                 not_a_struct([:union_type, [:union_type, :not_of_type_struct]])
               ])
    end

    test "keeps the errors of each alternative in declaration order" do
      assert {:error, %Failure{errors: errors}} =
               Validations.union("x", left_nested(@below_10, @below_100, @any_integer))

      assert Enum.map(errors, & &1.message) == [
               [:union_type, [:union_type, {:rejected_by, :below_10}]],
               [:union_type, [:union_type, {:rejected_by, :below_100}]],
               [:union_type, {:rejected_by, :any_integer}]
             ]
    end

    test "keeps all errors of an alternative that fails with several errors" do
      tuple = %Types.TupleT{inner: [%Types.IntegerT{}, %Types.IntegerT{}]}

      assert Validations.union({:a, :b}, [%Types.UnionT{inner: [tuple, @a]}, @b]) ==
               Failure.make([
                 Error.make(
                   :a,
                   [:union_type, [:union_type, [:tuple_type, :not_of_type_integer]]],
                   ValidatedStruct
                 ),
                 Error.make(
                   :b,
                   [:union_type, [:union_type, [:tuple_type, :not_of_type_integer]]],
                   ValidatedStruct
                 ),
                 Error.make(
                   {:a, :b},
                   [:union_type, [:union_type, :not_of_type_struct]],
                   ValidatedStruct
                 ),
                 Error.make({:a, :b}, [:union_type, :not_of_type_struct], ValidatedStruct)
               ])
    end
  end

  describe "a struct field typed as a union" do
    test "accepts each member of a left-nested union" do
      for event <- [%A{id: 1}, %B{id: 1}, %C{id: 1}] do
        assert UnionData.LeftNested.make(event: event) ==
                 {:ok, %UnionData.LeftNested{event: event}}
      end
    end

    test "accepts each member of a right-nested union" do
      for event <- [%A{id: 1}, %B{id: 1}, %C{id: 1}] do
        assert UnionData.RightNested.make(event: event) ==
                 {:ok, %UnionData.RightNested{event: event}}
      end
    end

    test "rejects a value matching no member of a left-nested union" do
      assert {:error, %Failure{errors: errors}} = UnionData.LeftNested.make(event: :nope)

      assert Enum.map(errors, & &1.message) == [
               [:event, [:union_type, [:union_type, :not_of_type_struct]]],
               [:event, [:union_type, [:union_type, :not_of_type_struct]]],
               [:event, [:union_type, :not_of_type_struct]]
             ]
    end

    test "rejects a value matching no member of a right-nested union" do
      assert {:error, %Failure{errors: errors}} = UnionData.RightNested.make(event: :nope)

      assert Enum.map(errors, & &1.message) == [
               [:event, [:union_type, :not_of_type_struct]],
               [:event, [:union_type, [:union_type, :not_of_type_struct]]],
               [:event, [:union_type, [:union_type, :not_of_type_struct]]]
             ]
    end

    test "uses the first matching member and skips the ones after it" do
      assert UnionData.ProbeLeftNested.make(value: 5) ==
               {:ok, %UnionData.ProbeLeftNested{value: {:below_10, 5}}}

      assert probed() == [:below_10]

      assert UnionData.ProbeRightNested.make(value: 50) ==
               {:ok, %UnionData.ProbeRightNested{value: {:below_100, 50}}}

      assert probed() == [:below_10, :below_100]
    end
  end
end
