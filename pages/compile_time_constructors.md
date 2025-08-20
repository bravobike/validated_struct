# Compile-Time-Safe Constructors

To have more robust constructors that show, e.g. typos in fields at compile time,
we can use macro constructors as follows:

```elixir
require Money

Money.make_safe(currency: :usd, amount: 23)
```

If we now pass a field that doesn't exist, we get an error at compile time.
This is also handy in refactoring where fields are renamed.
