defmodule ValidatedStructTest do
  alias ValidatedStructTest.Data

  use ExUnit.Case

  import ValidatedStruct.Matchers

  test "greets the world" do
    inner = Data.Inner.make!(bla: "hello", blub: "world")

    assert {:ok, %Data{hello: "123", bye: 678, world: ^inner}} =
             Data.make(hello: "123", bye: 678, world: inner)
  end

  test "uses validated types" do
    inner = Data.Inner.make(bla: "hello", blub: "")
    assert {:error, failure(:string_must_not_be_empty)} = inner
  end

  test "validate works as expected with success" do
    inner = %Data.Inner{bla: "hello", blub: "blub"} |> Data.Inner.validate()
    assert {:ok, _} = inner
  end

  test "validate works as expected with failure" do
    inner = %Data.Inner{bla: "hello", blub: ""} |> Data.Inner.validate()
    assert {:error, failure(:string_must_not_be_empty)} = inner
  end

  test "validate! works as expected with success" do
    inner = %Data.Inner{bla: "hello", blub: "blub"} |> Data.Inner.validate!()
    assert %Data.Inner{} = inner
  end

  test "validate! works as expected with failure" do
    assert_raise(RuntimeError, fn ->
      %Data.Inner{bla: "hello", blub: ""} |> Data.Inner.validate!()
    end)
  end

  test "struct validation works as expected" do
    assert {:ok, _} = Data.Inner.make(bla: "hello", blub: "world!")
    assert {:error, failure(:should_not_be_equal)} = Data.Inner.make(bla: "hello", blub: "hello")
  end

  describe "validation functions" do
    test "validation_result?/1 works as expected" do
      assert ValidatedStruct.validation_result?(ValidatedStruct.Success.make(12))
      assert ValidatedStruct.validation_result?(ValidatedStruct.Failure.make([]))
      refute ValidatedStruct.validation_result?(%{})
    end

    test "map_success/2 works as expected" do
      success = ValidatedStruct.Success.make(0)
      assert ValidatedStruct.map_success(success, fn a -> a + 1 end) == {:ok, 1}

      failure = ValidatedStruct.Failure.make([])

      assert {:error, %ValidatedStruct.Failure{errors: []}} =
               ValidatedStruct.map_success(failure, fn a -> a + 1 end)
    end

    test "map_failure/2 works as expected" do
      success = ValidatedStruct.Success.make(0)
      assert ValidatedStruct.map_failure(success, fn a -> a + 1 end) == {:ok, 0}

      failure = ValidatedStruct.Failure.make([ValidatedStruct.Error.make(1, :hello, :hello)])

      assert {:error,
              %ValidatedStruct.Failure{
                errors: [%ValidatedStruct.Error{candidate: 2, message: :hello, context: :hello}]
              }} =
               ValidatedStruct.map_failure(failure, fn err ->
                 %ValidatedStruct.Error{err | candidate: 2}
               end)
    end

    test "map/2 works as expected" do
      success = ValidatedStruct.Success.make(0)

      assert {:ok, 1} ==
               ValidatedStruct.map(success, fn a -> a + 1 end, fn _ -> :does_nothing end)

      failure = ValidatedStruct.Failure.make([ValidatedStruct.Error.make(1, :hello, :hello)])

      assert {:error,
              %ValidatedStruct.Failure{
                errors: [%ValidatedStruct.Error{candidate: 2, message: :hello, context: :hello}]
              }} =
               ValidatedStruct.map(failure, fn _ -> :does_nothing end, fn err ->
                 %ValidatedStruct.Error{err | candidate: 2}
               end)
    end

    test "pure/1 works as expected" do
      assert ValidatedStruct.pure(12) == {:ok, 12}
    end

    test "success/1 works as expected" do
      assert ValidatedStruct.success(12) == {:ok, 12}
    end

    test "agument_contexts/2 works as expected" do
      assert ValidatedStruct.pure(12) |> ValidatedStruct.augment_contexts(Hello) == {:ok, 12}

      error_1 = ValidatedStruct.Error.make(1, :message, Context)
      error_2 = ValidatedStruct.Error.make(2, :message, AnotherContext)
      failure = ValidatedStruct.Failure.make([error_1, error_2])

      ret = ValidatedStruct.augment_contexts(failure, AdditionalContext)

      assert {:error,
              %ValidatedStruct.Failure{
                errors: [
                  %ValidatedStruct.Error{
                    candidate: 1,
                    message: :message,
                    context: [AdditionalContext, Context]
                  },
                  %ValidatedStruct.Error{
                    candidate: 2,
                    message: :message,
                    context: [AdditionalContext, AnotherContext]
                  }
                ]
              }} = ret
    end

    test "agument_messages/2 works as expected" do
      assert ValidatedStruct.pure(12) |> ValidatedStruct.override_messages(Hello) == {:ok, 12}

      error_1 = ValidatedStruct.Error.make(1, :message, Context)
      error_2 = ValidatedStruct.Error.make(2, :another_message, Context)
      failure = ValidatedStruct.Failure.make([error_1, error_2])
      ret = ValidatedStruct.override_messages(failure, :additional_message)

      assert {:error,
              %ValidatedStruct.Failure{
                errors: [
                  %ValidatedStruct.Error{
                    candidate: 1,
                    message: :additional_message,
                    context: Context
                  },
                  %ValidatedStruct.Error{
                    candidate: 2,
                    message: :additional_message,
                    context: Context
                  }
                ]
              }} = ret
    end

    test "override_contexts/1 works as expected" do
      assert ValidatedStruct.pure(12) |> ValidatedStruct.override_contexts(Hello) == {:ok, 12}

      error_1 = ValidatedStruct.Error.make(1, :message, Context)
      error_2 = ValidatedStruct.Error.make(2, :another_message, Context)
      failure = ValidatedStruct.Failure.make([error_1, error_2])

      ret = ValidatedStruct.override_contexts(failure, NewContext)

      assert {:error,
              %ValidatedStruct.Failure{
                errors: [
                  %ValidatedStruct.Error{candidate: 1, message: :message, context: NewContext},
                  %ValidatedStruct.Error{
                    candidate: 2,
                    message: :another_message,
                    context: NewContext
                  }
                ]
              }} = ret
    end

    test "seq/2 works as expected" do
      s1 = ValidatedStruct.Success.make(fn a -> a + 1 end)
      s2 = ValidatedStruct.Success.make(0)
      assert ValidatedStruct.seq(s1, s2) == {:ok, 1}

      error = ValidatedStruct.Error.make(:hello, "not allowed", nil)
      failure = ValidatedStruct.Failure.make([error])
      success = ValidatedStruct.Success.make(1)

      assert {:error, %ValidatedStruct.Failure{errors: [^error]}} =
               ValidatedStruct.seq(failure, success)

      error1 = ValidatedStruct.Error.make(:hello, "not allowed", nil)
      error2 = ValidatedStruct.Error.make(:world, "not allowed", nil)
      failure1 = ValidatedStruct.Failure.make([error1])
      failure2 = ValidatedStruct.Failure.make([error2])

      assert {:error, %ValidatedStruct.Failure{errors: [^error1, ^error2]}} =
               ValidatedStruct.seq(failure1, failure2)
    end

    test "and_then/2 works as expected" do
      assert ValidatedStruct.Success.make(0)
             |> ValidatedStruct.and_then(fn x -> ValidatedStruct.Success.make(x + 1) end) ==
               {:ok, 1}

      ret = ValidatedStruct.Failure.make([]) |> ValidatedStruct.and_then(fn x -> x + 1 end)
      assert {:error, %ValidatedStruct.Failure{errors: []}} = ret
    end

    test "validate/2 works as expected" do
      assert ValidatedStruct.validate(fn a, b -> {a, b} end, [
               ValidatedStruct.Success.make(1),
               ValidatedStruct.Success.make(2)
             ]) == {:ok, {1, 2}}

      error1 = ValidatedStruct.Error.make(:hello, "not allowed", nil)
      error2 = ValidatedStruct.Error.make(:world, "not allowed", nil)
      failure1 = ValidatedStruct.Failure.make([error1])
      failure2 = ValidatedStruct.Failure.make([error2])
      ret = ValidatedStruct.validate(fn a, b -> {a, b} end, [failure1, failure2])
      assert {:error, %ValidatedStruct.Failure{errors: [^error1, ^error2]}} = ret
    end

    test "sequence/1 works as expected" do
      assert ValidatedStruct.sequence([
               ValidatedStruct.Success.make(1),
               ValidatedStruct.Success.make(2)
             ]) == {:ok, [1, 2]}

      error1 = ValidatedStruct.Error.make(:hello, "not allowed", nil)
      error2 = ValidatedStruct.Error.make(:world, "not allowed", nil)
      failure1 = ValidatedStruct.Failure.make([error1])
      failure2 = ValidatedStruct.Failure.make([error2])
      ret = ValidatedStruct.sequence([failure1, failure2])
      assert {:error, %ValidatedStruct.Failure{errors: [^error1, ^error2]}} = ret
    end

    test "sequence_of/2 works as expected" do
      success_fn = fn c -> ValidatedStruct.Success.make(c) end
      assert ValidatedStruct.sequence_of([1, 2], success_fn) == {:ok, [1, 2]}

      failure_fn = fn c ->
        [ValidatedStruct.Error.make(c, "not allowed", nil)] |> ValidatedStruct.Failure.make()
      end

      ret = ValidatedStruct.sequence_of([:hello, :world], failure_fn)

      error1 = ValidatedStruct.Error.make(:hello, [{:index, 0}, "not allowed"], nil)
      error2 = ValidatedStruct.Error.make(:world, [{:index, 1}, "not allowed"], nil)

      assert {:error, %ValidatedStruct.Failure{errors: [^error1, ^error2]}} = ret
    end

    test "validate_all/2 works as expected" do
      success_fn_1 = fn c -> ValidatedStruct.Success.make(c) end
      success_fn_2 = fn _ -> ValidatedStruct.Success.make(12) end
      assert ValidatedStruct.validate_all([success_fn_1, success_fn_2], 1) == {:ok, 1}

      failure_fn = fn c ->
        [ValidatedStruct.Error.make(c, "not allowed", nil)] |> ValidatedStruct.Failure.make()
      end

      success_fn = fn _ -> ValidatedStruct.Success.make(12) end
      ret = ValidatedStruct.validate_all([failure_fn, success_fn], :hello)

      error = ValidatedStruct.Error.make(:hello, [{:index, 0}, "not allowed"], nil)

      assert {:error, %ValidatedStruct.Failure{errors: [^error]}} = ret
    end
  end
end
