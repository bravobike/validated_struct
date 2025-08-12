defmodule ValidatedStruct.Error do
  @moduledoc """
  Module containing data definition and functionality concerning an Error.
  An Error is a struct representing a concrete error in validation.

  An Error consists of the following:

  * A candidate, representing the value that was validated
  * A message, describing the cause of the Error
  * A context in which the Error occured, e.g. a module or step
  """

  alias __MODULE__

  import ValidatedStruct.Internal.ValidixirWrapper, only: [apply_translated: 2, translate: 1]

  @type t :: %Error{}
  @enforce_keys [:candidate, :message]
  defstruct [:candidate, :message, :context]

  @doc ~S"""
  Smart constructor of an error.
  """
  @spec make(any(), any(), any()) :: t()
  def make(candidate, message, context) do
    Validixir.Error.make(candidate, message, context) |> translate()
  end

  @doc ~S"""
  Overrides the context of an error.
  """
  @spec with_context(t(), any()) :: t()
  def with_context(error, context), do: apply_translated(&Validixir.Error.with_context(&1, context), error)

  @doc ~S"""
  Overrides the message of an error.
  """
  @spec with_message(t(), any()) :: t()
  def with_message(error, message), do: apply_translated(&Validixir.Error.with_message(&1, message), error)

  @doc ~S"""
  Augments the message of an error.
  """
  @spec augment_message(t(), any()) :: t()
  def augment_message(error, additional_message), do: apply_translated(&Validixir.Error.augment_message(&1, additional_message), error)

  @doc ~S"""
  Augments the context of an error.
  """
  @spec augment_context(t(), any()) :: t()
  def augment_context(error, additional_context), do: apply_translated(&Validixir.Error.augment_context(&1, additional_context), error)
end
