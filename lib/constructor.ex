defmodule ValidatedStruct.Constructor do
  alias TypeResolver

  defmacro expand(_) do
    module = __CALLER__.module

    defaults = Module.get_attribute(module, :struct_defaults)
    fields = Module.get_attribute(module, :field_type_mapping) |> Enum.reverse()
    struct_validation = Module.get_attribute(module, :__struct_validation__) || (&ValidatedStruct.success/1)

    field_names =
      fields
      |> Enum.map(fn
        {_, kw, _} -> kw
        {_, kw, _, _} -> kw
      end)

    field_mapping = field_names |> Enum.map(fn kw -> {kw, kw |> Macro.var(nil)} end)
    validations = validations(fields, __CALLER__)
    constructor = constructor(module, field_mapping, defaults)
    type_list = types(fields, __CALLER__)

    quote do
      Module.put_attribute(unquote(module), :__fields__, unquote(field_names))
      Module.put_attribute(unquote(module), :__defaults__, unquote(defaults))

      def __validations__(), do: [unquote_splicing(validations)]
      def __types__(), do: unquote(type_list |> Macro.escape())
      def __field_names__(), do: unquote(field_names)
      def __defaults__(), do: unquote(defaults)
      def __struct_validation__(), do: unquote(struct_validation)

      unquote(constructor)

      @spec unquote(update_name(module))(unquote(module).t(), keyword()) :: ValidatedStruct.validation_result_t(unquote(module).t())
      def unquote(update_name(module))(%unquote(module){} = s, opts) do
        Keyword.merge(
          Map.from_struct(s) |> Keyword.new(),
          opts
        )
        |> unquote(constructor_name(module))()
      end

      @spec unquote(update_bang_name(module))(unquote(module).t(), keyword()) :: unquote(module).t()
      def unquote(update_bang_name(module))(%unquote(module){} = s, opts) do
        case unquote(update_name(module))(s, opts) do
          {:ok, c} -> c
          {:error, %ValidatedStruct.Failure{}} = f -> raise inspect(f)
        end
      end

      @spec unquote(validate_name(module))(unquote(module).t()) :: ValidatedStruct.validation_result_t(unquote(module).t())
      def unquote(validate_name(module))(s) do
        Map.from_struct(s)
        |> Keyword.new()
        |> unquote(constructor_name(module))()
      end

      @spec unquote(validate_bang_name(module))(unquote(module).t()) :: unquote(module).t()
      def unquote(validate_bang_name(module))(s) do
        case unquote(validate_name(module))(s) do
          {:ok, c} -> c
          {:error, %ValidatedStruct.Failure{}} = f -> raise inspect(f)
        end
      end
    end
  end

  defp names(field_name_var_mapping) do
    field_name_var_mapping |> Enum.map(&elem(&1, 0))
  end

  defp vars(field_name_var_mapping) do
    field_name_var_mapping |> Enum.map(&elem(&1, 1))
  end

  defp validation_fun(module, field_mapping) do
    args = Macro.generate_unique_arguments(Enum.count(field_mapping), __MODULE__)
    names = names(field_mapping)

    field_mapping = Enum.zip(names, args)

    vars = vars(field_mapping)

    if only_type_validation?(module) do
      quote do
        fn unquote_splicing(vars) -> unquote(field_mapping) end
      end
    else
      quote do
        fn unquote_splicing(vars) ->
          %__MODULE__{unquote_splicing(field_mapping)}
        end
      end
    end
  end

  defp constructor_name(module) do
    Module.get_attribute(module, :__only_type_validation_name__) ||
      Module.get_attribute(module, :__private_constructor_name__) ||
      Module.get_attribute(module, :__constructor_name__)
  end

  # Called only during compiletime, hence the atom generation is considered
  # limited and sane
  # sobelow_skip ["DOS.BinToAtom"]
  defp constructor_bang_name(module) do
    :"#{constructor_name(module)}!"
  end

  defp update_name(module) do
    Module.get_attribute(module, :__update_name__)
  end

  # Called only during compiletime, hence the atom generation is considered
  # limited and sane
  # sobelow_skip ["DOS.BinToAtom"]
  defp update_bang_name(module) do
    :"#{update_name(module)}!"
  end

  defp validate_name(module) do
    Module.get_attribute(module, :__validate_name__)
  end

  # Called only during compiletime, hence the atom generation is considered
  # limited and sane
  # sobelow_skip ["DOS.BinToAtom"]
  defp validate_bang_name(module) do
    :"#{validate_name(module)}!"
  end

  defp constructor_private?(module) do
    Module.get_attribute(module, :__private_constructor_name__, false)
  end

  defp only_type_validation?(module) do
    Module.get_attribute(module, :__only_type_validation_name__, false)
  end

  defp constructor_body(field_mapping, validation_fun, defaults) do
    quote do
      ValidatedStruct.validate(
        unquote(validation_fun),
        Enum.map(unquote(names(field_mapping)), &Keyword.get(arg, &1, Keyword.get(unquote(defaults), &1)))
        |> Enum.zip(__validations__())
        |> Enum.zip(unquote(vars(field_mapping) |> Enum.map(&elem(&1, 0))))
        |> Enum.map(fn {{arg, v}, arg_name} ->
          v.(arg) |> ValidatedStruct.augment_messages(arg_name)
        end)
      )
      |> ValidatedStruct.override_contexts(__MODULE__)
      |> ValidatedStruct.and_then(__MODULE__.__struct_validation__())
    end
  end

  # only called during compiletime
  # sobelow_skip ["DOS.BinToAtom"]
  defp constructor(module, field_mapping, defaults) do
    validation_fun = validation_fun(module, field_mapping)
    constructor_body = constructor_body(field_mapping, validation_fun, defaults)
    constructor_name = constructor_name(module)
    constructor_bang_name = constructor_bang_name(module)
    required_keys = Keyword.keys(field_mapping) -- Keyword.keys(defaults)

    if constructor_private?(module) do
      quote do
        defp unquote(constructor_name)(arg) do
          unquote(constructor_body)
        end

        defp unquote(constructor_bang_name)(arg) do
          case unquote(constructor_name(module))(s, opts) do
            {:ok, c} -> c
            {:error, %ValidatedStruct.Failure{}} = f -> raise inspect(f)
          end
        end
      end
    else
      macro =
        quote bind_quoted: [constructor_name: constructor_name, constructor_bang_name: constructor_bang_name, module: module, required_keys: required_keys] do
          defmacro unquote(:"#{constructor_name}_safe")(arg) do
            call = unquote(constructor_name)
            m = unquote(module)

            quote do
              _check = %unquote(m){unquote_splicing(arg)}
              Kernel.apply(unquote(m), unquote(call), [unquote(arg)])
            end
          end

          defmacro unquote(:"#{constructor_name}_safe!")(arg) do
            call = unquote(constructor_bang_name)
            m = unquote(module)

            quote do
              _check = %unquote(m){unquote_splicing(arg)}
              Kernel.apply(unquote(m), unquote(call), [unquote(arg)])
            end
          end
        end

      [
        quote do
          @spec unquote(constructor_name)(keyword()) :: ValidatedStruct.validation_result_t(unquote(module).t())
          def unquote(constructor_name)(arg) do
            unquote(constructor_body)
          end
        end,
        quote do
          def unquote(constructor_bang_name)(arg) do
            case unquote(constructor_name(module))(arg) do
              {:ok, c} -> c
              {:error, %ValidatedStruct.Failure{}} = f -> raise inspect(f)
            end
          end
        end,
        macro
      ]
    end
  end

  defmacro make_safe(module, arg) do
    quote do
      _check = %unquote(module){
        unquote_splicing(arg)
      }

      Kernel.apply(unquote(module), :make, [unquote(arg)])
    end
  end

  defmacro make_safe!(module, arg) do
    quote do
      _check = %unquote(module){
        unquote_splicing(arg)
      }

      Kernel.apply(unquote(module), :make!, [unquote(arg)])
    end
  end

  defp types(fields, caller) do
    Enum.map(fields, fn
      {:type, _n, type} ->
        {:ok, t} = TypeResolver.resolve(type, caller)
        t

      {:validation, _n, _validation, type} ->
        {:ok, t} = TypeResolver.resolve(type, caller)
        t
    end)
  end

  defp validations(fields, caller) do
    Enum.map(fields, fn
      {:type, _n, type} ->
        t =
          case TypeResolver.resolve(type, caller) do
            {:ok, t} -> t
            err -> raise "Cannot resolve #{inspect(type)}: #{inspect(err)}"
          end

        quote do
          ValidatedStruct.Mappings.validation(unquote(t |> Macro.escape()))
        end

      {:validation, _n, validation, _} ->
        case validation do
          # we need to explicitly build the ast for this function
          validation when is_atom(validation) ->
            quote do
              fn arg -> unquote(validation)(arg) end
            end

          _ ->
            quote do
              unquote(validation)
            end
        end
    end)
  end
end
