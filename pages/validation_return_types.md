# Validation Return Types

The validation semantics used by validated struct define a validation as a function of one parameter that returns a success or a failure. In the following sections, we explain the return types in detail:

## Success

A success is an ok-tuple: `{:ok, value}`. The value is the validated value, which, due to the given semantics, could've altered from the original validation candidate. Logic surrounding the 

## Failure

A failure is an error-tuple: `{:error, failure}`. The failure is a complex object, that contains multiple errors, one for each failing field. Each error consists of an error message, an error context and the original candidate that was validated. The context specifies where the validation took place (e.g. the struct module).

Since there are many errors in a failure but we may want to match for a specific error, we introduced failure matchers.

### Messages

All messages of all errors in a failure can be augmented or overridden. Augmenting is prepending an additional message as list items in front of the existing messages. This mechanism comes handy when you want to enrich the message with contextual information, e.g. ids or hints, that are not available within the validation's scope.

### Contexts

The context of all errors in a failure can be augmented or overridden. Contexts are meant to give hints, where an error occurred. By augmenting contexts, which means prepending a new context to the existing one(s), we can build a trace when we pass the validation through multiple layers.

## Matching Failures

A failure is an error-tuple with a `ValidatedStruct.Failure`-struct as the second value. A failure contains a list of errors, as validation is applied to every field at once.

We can match failures using a little helper, as follows:

```elixir
import ValidatedStruct.Matchers
{:error, failure(:amount)} = Money.make(amount: "bla", currency: :cad)
```
