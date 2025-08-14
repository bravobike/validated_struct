# ValidatedStruct

![Tests](https://github.com/bravobike/validated_struct/actions/workflows/main.yaml/badge.svg)
[![Hex version badge](https://img.shields.io/hexpm/v/validated_struct.svg)](https://hex.pm/packages/validated_struct)

ValidatedStruct is a library to define struct that come with built-in validation
based on specs.

ValidatedStruct is a plugin for type struct.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `validated_struct` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:validated_struct, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/validated_struct>.



## Example:

```elixir
defmodule Money do
  use ValidatedStruct

  validatedstruct do
      field :amount, non_neg_integer()
      field :currency, :eur | :usd
  end
end
```

The above code generates function called `make` and `update` that can be used
to create and update structs with validation:

```elixir
{:ok, money} = Money.make(amount: 10, currency: :eur)
{:ok, updated_money} = Money.update(acount: 11)

{:error, _} = Money.make(amount: 10, currency: :cad)
{:error, _} = Money.make(amount: "10", currency: :usd)
```

Fields in validated structs are always enforced.

## Failures

If validation doesn't succeed with a success, a failure is returned.
A failure is an error-tuple with a `ValidatedStruct.Failure`-struct as the second
value. A failure contains a list of errors, as validation is applied to every
field at once.

We can match failures using a little helper, as follows:

```elixir
import ValidatedStruct.Matchers
{:error, failure(:amount)} = Money.make(amount: "bla", currency: :cad)
```

Each error in a failure contains the candidate that was validated, a message,
as well as a context of the error occurance.

## Type resolution and type exporter

To resolve the types in the specs and derive validations from it, validated struct
relies on `Code.Typespec.fetch_specs/1` which in some circumstances doesn't work
as expected.

This results in an error in compilation, because types cannot be resolved. To circumvent
this, validated struct offers a module called `ValidatedStruct.TypeExporter` which
can be used in the module the type resides, as follows:

```elixir
defmodule MyTypesModule do
  use ValidatedStruct.TypeExporter

  # type that is guaranteed to be resolvable
  @type my_type :: String.t() | nil
end
```

Using the type exporter we guarantee, that types can be resolved by validated
struct. Note that types in modules from other umbrella apps, as well as libraries
can always be resolved (due to compiler internals).

## Overriding type validation

Sometimes validation is required to cover more, than just types. Furthermore,
expressivenes of specs is limited. 
To override type validation for a specific field, we can use an optional
`validation` argument at field level:

```elixir
validatedstruct do
  field :even, integer(), validation: &Validations.validate_even/1
  field :odd, integer(), validation: &Validations.validate_odd/1
end
```

Note that validation functions provided have arity one and need to return
`{:ok, any()}` in case of success and `{:error, Failure.t()}` in case of
a validation failure.

## Cross-field validation

To validate across multiple fields we can set the `struct_validation`-option as so:
    
```elixir
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
```

## Macro constructors

To have more robust constructors that show e.g. typos in fields at compile time,
we can use macro constructors as follows:

```elixir
require Money

Money.make_safe(currency: :usd, amount: 23)
```

If we now pass a field that doesn't exist we get an error at compile time.
This is also handy in refactoring where fields are renamed.

## Renaming functions

Constructors can be renamed by passing the option to the validated struct calls
as follows:

```elixir
validatedstruct constructor: :new do
  field :amount, non_neg_integer()
  field :currency, :eur | :usd
end

new(amount: 23, currency: :usd)
```

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

```elixir
use ValidatedStruct.TypeExporter 
@validated_type non_empty_string_t :: String.t(), validation: &Validation.validate_non_empty_string/1 
```

Given that, we can now use `non_empty_string_t` in a validated
struct without always having to define field wise custom validations.

## Generators

See `ValidatedStruct.Generator`.

## Hot code reloading in releases

ValidatedStruct heavily relies on debug information, which are usually stripped in
production code.

You have to add `strip_beams: [keep: ["Dbgi"]]` in your release config in
root > mix.exs > &project/0 > releases > <release_name>
