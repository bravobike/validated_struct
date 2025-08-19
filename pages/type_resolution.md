# Type Resolution and Type Exporter

Sometimes validated struct can not resolve a self-defined type that we define in our struct's specs. To make types available, we offer the module `TypeExporter`, which can be used as follows:

```elixir
defmodule MyTypesModule do
  use ValidatedStruct.TypeExporter

  # type that is guaranteed to be resolvable
  @type my_type :: String.t() | nil
end
```

Given that, the type `my_type` can always be resolved by the validated struct library.

Validated struct uses the [type_resolver](https://www.hex.pm/packages/type_resolver/0.1.7) library, to lift specs into compile-time usable values. `type_resolver` allows us to interpret and store spec types as well-structured structs, without the need of an extra compiler path. It uses internal methods for retrieving specs from other modules (`Code.Typespec.fetch_specs/1`). 

