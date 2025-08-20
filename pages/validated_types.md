# Validated types

Oftentimes, we have a spec type that we use in many places, that comes with a custom validation.
It then turns out, that it is cumbersome to pass the `validation` option in the field definition over and over
again. Validated types are for convenience in these situations.

They allow to directly associate a validation with a given type, as follows:

```elixir
use ValidatedStruct.TypeExporter 
@validated_type non_empty_string_t :: String.t(), validation: &Validation.validate_non_empty_string/1 
````

Given that, we can now use `non_empty_string_t` in a validated struct without always having to define field-wise custom validations. The validation given in the `@validated_type`-macro will now automatically be applied.
