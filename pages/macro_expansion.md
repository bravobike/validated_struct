# Macro Expansion explained

`ValidatedStruct` is implemented as a `TypedStruct` plugin. Let's take a look at the following struct:

```elixir
defmodule Money do
  use ValidatedStruct

  validatedstruct do
      field :amount, non_neg_integer()
      field :currency, :eur | :usd
  end
end
```

The macro calls generate the following code:

```
defmodule Money do
  use ValidatedStruct.TypeExporter
  use TypedStruct

  typedstruct do
      plugin ValidatedStruct

      field :amount, non_neg_integer()
      field :currency, :eur | :usd
  end
  
  # the constructor and update functions are generated eventually
  
  def make(...) do
    ...
  end

  def make!(...) do
    ...
  end
  
  ...
end
```

Thanks to `TypedStruct`'s awesome plugin-mechanism, we don't have to do much heavy lifting.
