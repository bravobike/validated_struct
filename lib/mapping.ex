defmodule ValidatedStruct.Mappings do
  @moduledoc """
    This modules maps resolved types to validations.
  """
  alias TypeResolver.Types
  alias ValidatedStruct.Validations

  def validation(t) do
    case t do
      %Types.NamedType{} -> maybe_use_type_bound_validation(t)
      %Types.BinaryT{} -> &Validations.binary/1
      %Types.IntegerT{} -> &Validations.integer/1
      %Types.StructL{module: s} -> &Validations.struct(&1, s)
      %Types.AtomT{} -> &Validations.atom/1
      %Types.AnyT{} -> &Validations.any/1
      # fixme: sc-7872 - we should have a struct here, not an actual list
      [%Types.AnyT{}] -> &Validations.list(&1, %Types.AnyT{})
      %Types.NoneT{} -> &Validations.none/1
      %Types.MapAnyT{} -> &Validations.map/1
      %Types.EmptyMapL{} -> &Validations.empty_map/1
      %Types.TupleAnyT{} -> &Validations.tuple/1
      %Types.PidT{} -> &Validations.pid/1
      %Types.PortT{} -> &Validations.port/1
      %Types.ReferenceT{} -> &Validations.reference/1
      %Types.TupleT{inner: inner} -> &Validations.tuple(&1, inner)
      %Types.UnionT{inner: inner} -> &Validations.union(&1, inner)
      %Types.FloatT{} -> &Validations.float/1
      %Types.PosIntegerT{} -> &Validations.pos_integer/1
      %Types.NonNegIntegerT{} -> &Validations.non_neg_integer/1
      %Types.NegIntegerT{} -> &Validations.neg_integer/1
      %Types.BooleanT{} -> &Validations.boolean/1
      %Types.ListT{inner: inner} -> &Validations.list(&1, inner)
      %Types.MapL{inner: inner} -> &Validations.map(&1, inner)
      %Types.MapFieldAssocL{k: k, v: v} -> &Validations.map_field_assoc(&1, k, v)
      %Types.MapFieldExactL{k: k, v: v} -> &Validations.map_field_exact(&1, k, v)
      %Types.EmptyListL{} -> &Validations.empty_list(&1)
      %Types.NonemptyListT{inner: inner} -> &Validations.nonempty_list(&1, inner)
      %Types.AtomL{value: v} -> &Validations.atom(&1, v)
      %Types.BooleanL{value: v} -> &Validations.boolean(&1, v)
      %Types.EmptyBitstringL{} -> &Validations.empty_bitstring(&1)
      %Types.SizedBitstringL{size: s} -> &Validations.sized_bitstring(&1, s)
      %Types.IntegerL{value: v} -> &Validations.integer(&1, v)
      %Types.FunctionL{arity: a} -> &Validations.fun(&1, a)
      %Types.RangeL{from: f, to: t} -> &Validations.range(&1, f, t)
      %Types.NilL{} -> &Validations.nil?(&1)
    end
  end

  defp maybe_use_type_bound_validation(%Types.NamedType{} = named_type) do
    Code.ensure_compiled!(named_type.module)

    if Kernel.function_exported?(named_type.module, :__validation_for, 1) do
      case named_type.module.__validation_for(named_type.name) do
        nil -> validation(named_type.inner)
        type_validation -> type_validation
      end
    else
      validation(named_type.inner)
    end
  end
end
