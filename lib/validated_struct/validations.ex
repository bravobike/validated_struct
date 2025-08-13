defmodule ValidatedStruct.Validations do
  alias TypeResolver.Types.MapFieldAssocL
  alias TypeResolver.Types.MapFieldExactL
  alias ValidatedStruct
  alias ValidatedStruct.Error
  alias ValidatedStruct.Failure
  alias ValidatedStruct.Internal.Mappings
  alias ValidatedStruct.Success

  def failure(candidate, error_msg) do
    ValidatedStruct.failure_from_error(candidate, error_msg, ValidatedStruct)
  end

  defdelegate success(c), to: ValidatedStruct

  def any(c), do: success(c)

  def none(c), do: failure(c, :not_of_type_none)

  def atom(c) when is_atom(c), do: success(c)
  def atom(c), do: failure(c, :not_of_type_atom)

  def map(c) when is_map(c), do: success(c)
  def map(c), do: failure(c, :not_of_type_map)

  def empty_map(c) when is_map(c) do
    if Map.keys(c) |> Enum.empty?() do
      success(c)
    else
      failure(c, :not_of_type_empty_map)
    end
  end

  def tuple(c) when is_tuple(c), do: success(c)
  def tuple(c), do: failure(c, :not_of_type_tuple)

  def pid(c) when is_pid(c), do: success(c)
  def pid(c), do: failure(c, :not_of_type_pid)

  def port(c) when is_port(c), do: success(c)
  def port(c), do: failure(c, :not_of_type_port)

  def reference(c) when is_reference(c), do: success(c)
  def reference(c), do: failure(c, :not_of_type_reference)

  def tuple(c, types) when is_tuple(c) do
    validations = Enum.map(types, &Mappings.validation(&1))

    Tuple.to_list(c)
    |> Enum.zip(validations)
    |> Enum.map(fn {candidate, validation} -> validation.(candidate) end)
    |> ValidatedStruct.sequence()
    |> ValidatedStruct.map(&List.to_tuple/1, &Error.augment_message(&1, :tuple_type))
  end

  def tuple(c, _types) do
    failure(c, :not_of_type_tuple)
  end

  def union(c, types) do
    res = Enum.map(types, &Mappings.validation(&1)) |> Enum.map(& &1.(c))
    maybe_success = find_success(res)

    if Success.success?(maybe_success) do
      maybe_success
    else
      ValidatedStruct.sequence(res)
      |> ValidatedStruct.map_failure(&Error.augment_message(&1, :union_type))
    end
  end

  def float(c) when is_float(c), do: success(c)
  def float(c), do: failure(c, :not_of_type_float)

  def integer(c) when is_integer(c), do: success(c)
  def integer(c), do: failure(c, :not_of_type_integer)

  def binary(c) when is_binary(c), do: success(c)
  def binary(c), do: failure(c, :not_of_type_binary)

  def non_neg_integer(c) do
    integer(c)
    |> ValidatedStruct.override_messages(:not_of_type_non_neg_integer)
    |> ValidatedStruct.and_then(fn _ ->
      if c >= 0 do
        success(c)
      else
        failure(c, :not_of_type_non_neg_integer)
      end
    end)
  end

  def neg_integer(c) do
    integer(c)
    |> ValidatedStruct.and_then(fn _ ->
      if c < 0 do
        success(c)
      else
        failure(c, :not_of_type_neg_integer)
      end
    end)
  end

  def pos_integer(c) do
    integer(c)
    |> ValidatedStruct.and_then(fn _ ->
      if c > 0 do
        success(c)
      else
        failure(c, :not_of_type_pos_integer)
      end
    end)
  end

  def boolean(c) when is_boolean(c), do: success(c)
  def boolean(c), do: failure(c, :not_of_type_boolean)

  def list(val) when is_list(val), do: ValidatedStruct.pure(val)
  def list(val), do: ValidatedStruct.failure_from_error(val, :not_a_list, __MODULE__)

  def list(c, inner) when is_list(c) do
    validation = Mappings.validation(inner)

    ValidatedStruct.sequence_of(c, validation)
    |> ValidatedStruct.augment_messages(:list_type)
    |> ValidatedStruct.augment_contexts(ValidatedStruct)
  end

  def list(c, _) do
    failure(c, :not_of_list_type)
  end

  def map(c, inner) when is_map(c) do
    map(c)
    |> ValidatedStruct.and_then(fn _ ->
      c_list = Map.to_list(c)

      all_values_valid? =
        Enum.all?(c_list, fn {k, v} ->
          Enum.map(inner, fn
            %MapFieldExactL{k: k_type, v: v_type} ->
              [Mappings.validation(k_type).(k), Mappings.validation(v_type).(v)]
              |> ValidatedStruct.sequence()

            %MapFieldAssocL{k: k_type, v: v_type} ->
              [Mappings.validation(k_type).(k), Mappings.validation(v_type).(v)]
              |> ValidatedStruct.sequence()
          end)
          |> Enum.any?(fn
            {:ok, _} -> true
            {:error, %Failure{}} -> false
          end)
        end)

      all_fields_valid? =
        Enum.all?(inner, fn
          %MapFieldExactL{k: k_type, v: v_type} ->
            Enum.map(c_list, fn {k, v} ->
              [Mappings.validation(k_type).(k), Mappings.validation(v_type).(v)]
            end)
            |> List.flatten()
            |> Enum.any?(fn
              {:ok, _} -> true
              {:error, %Failure{}} -> false
            end)

          %MapFieldAssocL{} ->
            true
        end)

      if all_values_valid? && all_fields_valid? do
        success(c)
      else
        failure(c, :map_type_does_not_match)
      end
    end)
  end

  def map(c, _inner) do
    failure(c, :not_of_type_map)
  end

  def map_field_exact(c, k, t) do
    map(c)
    |> ValidatedStruct.and_then(fn _ ->
      if Map.has_key?(c, k) do
        validation = Mappings.validation(t)

        Map.fetch!(c, k)
        |> then(fn c -> validation.(c) end)
        |> ValidatedStruct.augment_messages(k)
        |> ValidatedStruct.augment_messages(:field_type_does_not_match)
      else
        failure(c, k)
        |> ValidatedStruct.augment_messages(:field_missing)
      end
    end)
  end

  def map_field_assoc(c, _, _), do: success(c)

  def empty_list(c) when is_list(c) do
    if Enum.empty?(c) do
      success(c)
    else
      failure(c, :not_an_empty_list)
    end
  end

  def empty_list(c), do: failure(c, :not_an_empty_list)

  def nonempty_list(c, inner) when is_list(c) do
    list(c, inner)
    |> ValidatedStruct.and_then(fn _ ->
      if Enum.empty?(c) do
        failure(c, :not_of_type_empty_list)
      else
        success(c)
      end
    end)
  end

  def atom(c, v) do
    atom(c)
    |> ValidatedStruct.and_then(fn _ ->
      if c == v do
        success(c)
      else
        failure(c, :not_expected_atom)
      end
    end)
  end

  def nil?(c) do
    atom(c, nil)
    |> ValidatedStruct.map_failure(fn error -> Error.with_message(error, :not_nil) end)
  end

  def not_nil(val) when is_nil(val),
    do: ValidatedStruct.failure_from_error(val, :is_nil, __MODULE__)

  def not_nil(val), do: ValidatedStruct.pure(val)

  def boolean(c, bool) do
    message =
      if bool do
        :not_true
      else
        :not_false
      end

    atom(c, bool)
    |> ValidatedStruct.map_failure(fn error -> Error.with_message(error, message) end)
  end

  def empty_bitstring(<<>>), do: success(<<>>)
  def empty_bitstring(c), do: failure(c, :not_an_empty_bitstring)

  def sized_bitstring(c, size) do
    case c do
      <<_::size(^size)>> ->
        success(c)

      _ ->
        failure(c, {:expected_size, size})
        |> ValidatedStruct.augment_messages(:not_a_sized_bitstring)
    end
  end

  def integer(c, v) do
    integer(c)
    |> ValidatedStruct.and_then(fn _ ->
      if c == v do
        success(c)
      else
        failure(c, {:expected_integer, v})
        |> ValidatedStruct.augment_messages(:not_expected_integer)
      end
    end)
  end

  def fun(c, :any) when is_function(c), do: success(c)

  def fun(c, arity) when is_function(c, arity), do: success(c)

  def fun(c, arity),
    do:
      failure(c, {:expected_arity, arity})
      |> ValidatedStruct.augment_messages(:not_expected_function)

  def range(c, from, to) do
    integer(c)
    |> ValidatedStruct.and_then(fn _ ->
      if from <= c && c <= to do
        success(c)
      else
        failure(c, {:expected_range, from, to})
        |> ValidatedStruct.augment_messages(:not_in_expected)
      end
    end)
  end

  def struct(%s{} = c, v) do
    if s == v do
      success(c)
    else
      failure(c, {:expected_struct, v}) |> ValidatedStruct.augment_messages(:not_expected_struct)
    end
  end

  def struct(c, _), do: failure(c, :not_of_type_struct)

  defp find_success(list), do: Enum.find(list, &Success.success?/1)
end
