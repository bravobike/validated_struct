# General Usage

`ValidatedStruct` was created with the target in mind to have only validated and sound data in a system.

We want to define easily validatable structs and provide constructors, that utilize spec-derived validation.
The following example depicts the general usage:
  
  
```elixir
defmodule Money do
  use ValidatedStruct

  validatedstruct do
      field :amount, non_neg_integer()
      field :currency, :eur | :usd
  end
end
```

The above code generates functions called `make` and `update` that can be used
to create and update structs with validation:

```elixir
{:ok, money} = Money.make(amount: 10, currency: :eur)
{:ok, updated_money} = Money.update(amount: 11)

{:error, _} = Money.make(amount: 10, currency: :cad)
{:error, _} = Money.make(amount: "10", currency: :usd)
```

Fields in validated structs are always enforced.

In a project, having the requirement that all structured data has to be sound, we ditch the built-in construction as well as update syntax. Sadly, in elixir, we have no way to hide the built-in constructor. 

Using `make` and `update` forces the developer to handle validation errors explicitly. While this is intended, it can get cumbersome at some point. Thus, we included `make!` and `update!` which either return the validated value or raises, if validation fails.
