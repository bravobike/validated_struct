# ValidatedStruct

![Tests](https://github.com/bravobike/validated_struct/actions/workflows/main.yaml/badge.svg)
[![Hex version badge](https://img.shields.io/hexpm/v/validated_struct.svg)](https://hex.pm/packages/validated_struct)

ValidatedStruct is a library to define struct that come with built-in validation based on specs.

ValidatedStruct is a plugin for type struct.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `validated_struct` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:validated_struct, "~> 0.0.2"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/validated_struct>.

## Example

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
{:ok, updated_money} = Money.update(acount: 11)

{:error, _} = Money.make(amount: 10, currency: :cad)
{:error, _} = Money.make(amount: "10", currency: :usd)
```

Fields in validated structs are always enforced.


## Overview

- [General Usage](pages/general_usage.md)
- [Adapting Validation](pages/adapting_validation.md)
- [Validation Return Types](pages/validation_return_types.md)
- [Type Resolution and Type Exporter](pages/type_resolution.md)
- [Validated Types](pages/validated_types.md)
- [Compile-Time safe Constructors](pages/compile_time_constructors.md)
- [Macro Expansion explained](pages/macro_expansion.md)
- [Validation on Steroids](pages/validation_on_steroids.md)


## Hot code reloading in releases

ValidatedStruct heavily relies on debug information, which is usually stripped in
production code.

You have to add `strip_beams: [keep: ["Dbgi"]]` in your release config in
root > mix.exs > &project/0 > releases > <release_name>


## Generators

There is a library, that adds stream data generators to validated struct. It can be found at [hex.pm](https://hex.pm/packages/validated_struct_generators).
