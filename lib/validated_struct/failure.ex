defmodule ValidatedStruct.Failure do
  @moduledoc """
  Module containing data definition and functionality concerning a Failure.
  A Failure is a error tuple that contains a Failure struct representing a failed validation.

  A Failure struct consists of the following:

  * A list of Errors, displaying multiple causes for the validation to fail.
  * A message lookup that is a map with all messages as keys. This lookup is
    used internally and should not be used directly.
  * Optional meta information that is defined by the user.
  """

  import ValidatedStruct.Internal.ValidixirWrapper, only: [apply_translated: 2, apply_translated: 3, translate: 1]

  alias __MODULE__
  alias ValidatedStruct.Error, as: Error

  @type failure_t :: %Failure{errors: list(Error.t()), meta: any(), __message_lookup: map()}
  @type t :: {:error, failure_t}
  @enforce_keys [:errors]
  @derive {Inspect, except: [:__message_lookup]}
  defstruct [:errors, :meta, :__message_lookup]

  @doc ~S"""
  Smart constructor of a failure.
  """
  @spec make(list(Error.t()), any()) :: t()
  def make(errors, meta \\ nil) do
    errors = Enum.map(errors, &translate/1)

    Validixir.Failure.make(errors, meta)
    |> translate()
  end

  @doc ~S"""
  Constructs a failure with one error based on error parameters.
  """
  @spec make_from_error(any(), any(), any()) :: t()
  def make_from_error(candidate, message, context),
    do: Validixir.Failure.make_from_error(candidate, message, context) |> translate()

  @doc ~S"""
  Applies a function to each error in a failure's errors.
  """
  @spec map(t(), (Error.t() -> Error.t())) :: t()
  def map(v, f), do: apply_translated(&Validixir.Failure.map(&1, f), v)

  @doc ~S"""
  Overrides the context of all errors of a failure.
  """
  @spec override_error_contexts(t(), any()) :: t()
  def override_error_contexts(v, new_context), do: apply_translated(&Validixir.Failure.override_error_contexts(&1, new_context), v)

  @doc ~S"""
  Overrides the message of all errors of a failure.
  """
  @spec override_error_messages(t(), any()) :: t()
  def override_error_messages(v, new_message), do: apply_translated(&Validixir.Failure.override_error_messages(&1, new_message), v)

  @doc ~S"""
  Combines two errors. That is, appending their error lists.
  """
  @spec combine(t(), t()) :: t()
  def combine(v1, v2), do: apply_translated(&Validixir.Failure.combine/2, v1, v2)

  @doc ~S"""
  Returns true if a value is a failure.
  """
  @spec failure?(any()) :: boolean()
  def failure?(v), do: apply_translated(&Validixir.Failure.failure?/1, v)

  @doc """
  Puts meta into the failure.
  """
  @spec put_meta(t(), any()) :: t()
  def put_meta(v, meta), do: apply_translated(&Validixir.Failure.put_meta(&1, meta), v)
end
