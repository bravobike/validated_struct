defmodule ValidatedStruct do
  @moduledoc """
  ValidatedStruct is a library to define struct that come with built-in validation
  based on specs.

  ValidatedStruct is a plugin for type struct.

  ## Example:

      defmodule Money do
        use ValidatedStruct

        validatedstruct do
            field :amount, non_neg_integer()
            field :currency, :eur | :usd
        end
      end

  The above code generates function called `make` and `update` that can be used
  to create and update structs with validation:

      {:ok, money} = Money.make(amount: 10, currency: :eur)
      {:ok, updated_money} = Money.update(acount: 11)

      {:error, _} = Money.make(amount: 10, currency: :cad)
      {:error, _} = Money.make(amount: "10", currency: :usd)

  Fields in validated structs are always enforced.

  ## Failures

  If validation doesn't succeed with a success, a failure is returned.
  A failure is an error-tuple with a `ValidatedStruct.Failure`-struct as the second
  value. A failure contains a list of errors, as validation is applied to every
  field at once.

  We can match failures using a little helper, as follows:

      import ValidatedStruct.Matchers
      {:error, failure(:amount)} = Money.make(amount: "bla", currency: :cad)

  Each error in a failure contains the candidate that was validated, a message,
  as well as a context of the error occurance.

  ## Type resolution and type exporter

  To resolve the types in the specs and derive validations from it, validated struct
  relies on `Code.Typespec.fetch_specs/1` which in some circumstances doesn't work
  as expected.

  This results in an error in compilation, because types cannot be resolved. To circumvent
  this, validated struct offers a module called `ValidatedStruct.TypeExporter` which
  can be used in the module the type resides, as follows:

      defmodule MyTypesModule do
        use ValidatedStruct.TypeExporter

        # type that is guaranteed to be resolvable
        @type my_type :: String.t() | nil
      end

  Using the type exporter we guarantee, that types can be resolved by validated
  struct. Note that types in modules from other umbrella apps, as well as libraries
  can always be resolved (due to compiler internals).

  ## Overriding type validation

  Sometimes validation is required to cover more, than just types. Furthermore,
  expressivenes of specs is limited. 
  To override type validation for a specific field, we can use an optional
  `validation` argument at field level:

      validatedstruct do
        field :even, integer(), validation: &Validations.validate_even/1
        field :odd, integer(), validation: &Validations.validate_odd/1
      end

  Note that validation functions provided have arity one and need to return
  `{:ok, any()}` in case of success and `{:error, Failure.t()}` in case of
  a validation failure.

  ## Cross-field validation

  To validate across multiple fields we can set the `struct_validation`-option as so:

      defmodule TwoDifferentWords do
         use ValidatedStruct

         validatedstruct struct_validation: &TwoDifferentWords.validate_two_words/1 do
           field :first, String.t()
           field :second, String.t()
         end

         def validate_two_words(%__MODULE__{first: first, second: second} = s) do
           if a == b do
             ValidatedStruct.failure_from_error(s, :words_not_different, __MODULE__)
           else
             {:ok, s}
           end
         end
      end

  ## Macro constructors

  To have more robust constructors that show e.g. typos in fields at compile time,
  we can use macro constructors as follows:

      require Money

      Money.make_safe(currency: :usd, amount: 23)

  If we now pass a field that doesn't exist we get an error at compile time.
  This is also handy in refactoring where fields are renamed.

  ## Renaming functions

  Constructors can be renamed by passing the option to the validated struct calls
  as follows:

      validatedstruct constructor: :new do
        field :amount, non_neg_integer()
        field :currency, :eur | :usd
      end

      new(amount: 23, currency: :usd)

  We can change the names for the following functions:

  - constructor: renames the constructor, default is `:make`
  - update: renames the update function, default is `:update`
  - validate: renames the validation function, default is `:validate`

  ## Setting the constructor private

  We can have a private constructor by setting the option `private_constructor` to true.

  ## Type validation only

  If we don't want to have a smart constructor, we can pass the option
  `type_validation_only`. The options takes a name for the type validation
  function.

  This generates a function with the given name that only validates types
  and in case of a success returns the list of the validated inputs.

  ## Validated types

  For custom types, we can map validations directly onto them:

       use ValidatedStruct.TypeExporter 
       @validated_type non_empty_string_t :: String.t(), validation: &Validation.validate_non_empty_string/1 

  Given that, we can now use `non_empty_string_t` in a validated
  struct without always having to define field wise custom validations.

  ## Generators

  See `ValidatedStruct.Generator`.

  ## Hot code reloading in releases

  ValidatedStruct heavily relies on debug information, which are usually stripped in
  production code.

  You have to add `strip_beams: [keep: ["Dbgi"]]` in your release config in
  root > mix.exs > &project/0 > releases > <release_name>
  """
  use TypedStruct.Plugin

  @impl true
  @spec init(keyword()) :: Macro.t()
  defmacro init(opts) do
    check_invariants!(opts)

    quote do
      @before_compile {ValidatedStruct.Internal.Constructor, :expand}

      # setting up env for Constructor.expand
      Module.register_attribute(__MODULE__, :field_type_mapping, accumulate: true)
      Module.register_attribute(__MODULE__, :struct_defaults, accumulate: true)

      Module.put_attribute(__MODULE__, :__validated_struct__, true)

      Module.put_attribute(
        __MODULE__,
        :__constructor_name__,
        Keyword.get(unquote(opts), :constructor, :make)
      )

      Module.put_attribute(
        __MODULE__,
        :__update_name__,
        Keyword.get(unquote(opts), :update, :update)
      )

      Module.put_attribute(
        __MODULE__,
        :__validate_name__,
        Keyword.get(unquote(opts), :validate, :validate)
      )

      Module.put_attribute(
        __MODULE__,
        :__private_constructor_name__,
        Keyword.get(unquote(opts), :private_constructor)
      )

      Module.put_attribute(
        __MODULE__,
        :__only_type_validation_name__,
        Keyword.get(unquote(opts), :only_type_validation)
      )

      Module.put_attribute(
        __MODULE__,
        :__struct_validation__,
        Keyword.get(unquote(opts), :struct_validation)
      )
    end
  end

  @impl true
  @spec field(atom(), any(), keyword(), Macro.Env.t()) :: Macro.t()
  def field(name, type, opts, env) do
    mod = env.module
    maybe_custom_validation = Keyword.get(opts, :validation)

    if maybe_custom_validation do
      Module.put_attribute(
        mod,
        :field_type_mapping,
        {:validation, name, maybe_custom_validation, type}
      )
    else
      Module.put_attribute(mod, :field_type_mapping, {:type, name, type})
    end

    if Keyword.has_key?(opts, :default) do
      default = Keyword.get(opts, :default)
      Module.put_attribute(mod, :struct_defaults, {name, default})
    end

    nil
  end

  defmacro validatedstruct(opts \\ [], do: inner) do
    opts = Keyword.merge([enforce: true], opts)

    quote do
      typedstruct unquote(opts) do
        plugin(ValidatedStruct, unquote(opts))

        unquote(inner)
      end
    end
  end

  defmacro __using__(_) do
    quote do
      use TypedStruct
      use ValidatedStruct.TypeExporter
      import ValidatedStruct, only: [validatedstruct: 1, validatedstruct: 2]
    end
  end

  defp check_invariants!(opts) do
    only_type_validation? = Keyword.get(opts, :only_type_validation)
    struct_validation? = Keyword.get(opts, :struct_validation)

    if only_type_validation? && struct_validation? do
      raise "Struct validation is not applicable if only type validation is requested."
    end
  end

  ### functions for validation

  alias ValidatedStruct.Error, as: Error
  alias ValidatedStruct.Failure, as: Failure
  alias ValidatedStruct.Success, as: Success

  import ValidatedStruct.Internal.ValidixirWrapper,
    only: [apply_translated: 2, apply_translated: 3, with_translation: 1, translate: 1]

  @typedoc """
  A validation result is one of the following:

  * A failure
  * A success

  The type represents the possible results of a validation.
  The type takes a parameter that sets the candidate type in case of a success.
  """
  @type validation_result_t(inner_t) :: Failure.t() | Success.t(inner_t)

  @doc ~S"""
  Returns `true` if a value is either a `ValidatedStruct.Success` or a `ValidatedStruct.Failure`,
  returns `false` else.
  """
  @spec validation_result?(any()) :: boolean()
  def validation_result?(thing), do: apply_translated(&Validixir.validation_result?/1, thing)

  @doc ~S"""
  Applies a function to the candidate of a success. If a failure is passed it is
  returned unchanged.
  """
  @spec map_success(
          validation_result_t(Success.some_inner_t()),
          (Success.some_inner_t() -> any())
        ) :: validation_result_t(any())
  def map_success(v, f) do
    f = with_translation(f)
    apply_translated(&Validixir.map_success(&1, f), v)
  end

  @doc ~S"""
  Applies a function to each of the errors of a failure. If a success is passed it is
  returned unchanged.
  """
  @spec map_failure(validation_result_t(Success.some_inner_t()), (Error.t() -> Error.t())) ::
          validation_result_t(Success.some_inner_t())
  def map_failure(v, f) do
    f = with_translation(f)
    apply_translated(&Validixir.map_failure(&1, f), v)
  end

  @doc ~S"""
  Takes a validation result and two functions that are applied as in map_success/2 and
  map_failure/2 respectively.
  """
  @spec map(
          validation_result_t(Success.some_inner_t()),
          (Success.some_inner_t() -> any()),
          (Error.t() -> Error.t())
        ) :: validation_result_t(any())
  def map(v, f_success, f_failure) do
    f_success = with_translation(f_success)
    f_failure = with_translation(f_failure)
    apply_translated(&Validixir.map(&1, f_success, f_failure), v)
  end

  @doc ~S"""
  Takes a value and lifts it in a validation result, returning a success with the value
  as its candidate.
  """
  @spec pure(Success.some_inner_t()) :: Success.t(Success.some_inner_t())
  def pure(value), do: apply_translated(&Validixir.pure/1, value)

  @doc ~S"""
  Same as `pure/1`.
  """

  @spec success(Success.some_inner_t()) :: Success.t(Success.some_inner_t())
  def success(value), do: apply_translated(&Validixir.success/1, value)

  @doc ~S"""
  Augments a failure's error contexts if a failure is passed, else returns the success.
  """
  @spec augment_contexts(validation_result_t(Success.some_inner_t()), any()) ::
          validation_result_t(Success.some_inner_t())
  def augment_contexts(v, context),
    do: apply_translated(&Validixir.augment_contexts(&1, context), v)

  @doc ~S"""
  Augments a failure's error messages if a failure is passed, else returns the success.
  """
  @spec augment_messages(validation_result_t(Success.some_inner_t()), any()) ::
          validation_result_t(Success.some_inner_t())
  def augment_messages(v, messages),
    do: apply_translated(&Validixir.augment_messages(&1, messages), v)

  @doc ~S"""
  Overrides a failure's error messages if a failure is passed, else returns the success.
  """
  @spec override_messages(validation_result_t(Success.some_inner_t()), any()) ::
          validation_result_t(Success.some_inner_t())
  def override_messages(v, messages),
    do: apply_translated(&Validixir.override_messages(&1, messages), v)

  @doc ~S"""
  Overrides a failure's error contexts if a failure is passed, else returns the success.
  """
  @spec override_contexts(validation_result_t(Success.some_inner_t()), any()) ::
          validation_result_t(Success.some_inner_t())
  def override_contexts(v, contexts),
    do: apply_translated(&Validixir.override_contexts(&1, contexts), v)

  @doc ~S"""
  Applies a function wrapped in a validation success to the
  candidate of another validation success. If both validation results are failures
  it returns them combined. If only one is a failure, this failure is returned unchanged.

  This function is key in implementing applicatives.
  """
  @spec seq(
          validation_result_t((Success.some_inner_t() -> any())),
          validation_result_t(Success.some_inner_t())
        ) :: validation_result_t(any())
  def seq(v_1, v_2), do: apply_translated(&Validixir.seq/2, v_1, v_2)

  @doc ~S"""
  Takes a validation result and a function.
  In case of a success the function is applied to the candidate and the result is returned.
  In case of a failure that failure is returned unchanged.

  This function is used to chain validations.
  """
  @spec and_then(
          validation_result_t(Success.some_inner_t()),
          (Success.some_inner_t() -> validation_result_t(any()))
        ) :: validation_result_t(any())
  def and_then(validation_result, f) do
    f = with_translation(f)
    apply_translated(&Validixir.and_then(&1, f), validation_result)
  end

  @doc ~S"""
  Takes a function that is called if all validation results are successes. The call
  parameters are then the candidates in the respective order. The return value of this function
  call is then wrapped as a success and returned.

  If there is at least one failure, errors get accumulated and a validation failure is returned.
  """
  @spec validate(function(), [validation_result_t(any())]) :: validation_result_t(any())
  def validate(result_f, validations) do
    validations = Enum.map(validations, &translate/1)

    Validixir.validate(result_f, validations)
    |> translate()
  end

  @doc ~S"""
  Takes a list of validation results and returns a success that contains the list
  of all candidates, if all validation results are successes. Else all failures are
  combined and a validation failure is returned.
  """
  @spec sequence([validation_result_t(Success.some_inner_t())]) ::
          validation_result_t([Success.some_inner_t()])
  def sequence(l) do
    validations = Enum.map(l, &translate/1)

    Validixir.sequence(validations)
    |> translate()
  end

  @type validation_fun_t(result_t) :: (any() -> validation_result_t(result_t))

  @doc ~S"""
  Does the same as `ValidatedStruct.sequence/1` but applies a validation function
  to all candidates first.
  """
  @spec sequence_of([any()], validation_fun_t(Success.some_inner_t())) ::
          validation_result_t(Success.some_inner_t())
  def sequence_of(candidates, validation_f) do
    validation_f = with_translation(validation_f)

    Validixir.sequence_of(candidates, validation_f)
    |> translate()
  end

  @doc ~S"""
  Applies a list of validation functions to a candidate.
  Returns a success that contains the candidate if each validation function returns a success.
  Else returns a validation failure containing errors of each failed validation.
  """
  @type validate_all_return_t(inner_t) ::
          {:ok, validation_result_t(inner_t)} | {:error, :no_validators}
  @spec validate_all([validation_fun_t(Success.some_inner_t())], any()) ::
          validate_all_return_t(Success.some_inner_t())
  def validate_all([], _), do: {:error, :no_validators}

  def validate_all(validation_fs, candidate) do
    validation_fs = Enum.map(validation_fs, &with_translation/1)

    Validixir.validate_all(validation_fs, candidate)
    |> translate()
  end

  defdelegate failure_from_error(candidate, message, context),
    to: ValidatedStruct.Failure,
    as: :make_from_error
end
