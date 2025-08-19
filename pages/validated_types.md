# Validated types

For custom types, we can map validations directly onto them:

```elixir
use ValidatedStruct.TypeExporter 
@validated_type non_empty_string_t :: String.t(), validation: &Validation.validate_non_empty_string/1 
```

Given that, we can now use `non_empty_string_t` in a validated
struct without always having to define field-wise custom validations.
