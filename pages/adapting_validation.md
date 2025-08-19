# Adapting Validation

## Overriding type validation

Sometimes validation is required to cover more than just types. Furthermore,
expressiveness of specs is limited.
To override type validation for a specific field, we can use an optional
`validation` argument at the field level:

```elixir
validatedstruct do
  field :even, integer(), validation: &Validations.validate_even/1
  field :odd, integer(), validation: &Validations.validate_odd/1
end
```

Note that validation functions provided have arity one and need to return
`{:ok, new_value :: any()}` in case of success and `{:error, Failure.t()}` in case of
a validation failure.

In the case an `{:ok, new_value}` tuple is returned, the field will be set to
`new_value` without further validation.

## Cross-field validation

To validate across multiple fields, we can set the `struct_validation` option as so:

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

Note that struct validation is only applied if all single field validations succeed.

In the case an `{:ok, new_struct}` tuple is returned, the corresponding functions (`make`,
`update`) will return `new_struct` without further validation.


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

- `constructor:` renames the constructor, default is `:make`
- `update:` renames the update function, default is `:update`
- `validate:` renames the validation function, default is `:validate`

## Setting the constructor private

We can have a private constructor by setting the option `private_constructor` to true.


## Type validation only

If we don't want to have a smart constructor, we can pass the option
`type_validation_only`. The option takes a name for the type validation
function.

This generates a function with the given name that only validates types
and in case of a success returns the list of the validated inputs.
