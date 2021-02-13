defmodule Barna.OptionsTest do
  use ExUnit.Case, async: true

  alias Barna.Options

  describe "parse_opt_required!/2" do
    test "returns the opt if it exists in the opts list" do
      assert Options.parse_opt_required!([a: 1, b: 2], :b) == 2
    end

    test "returns the opt if it exists in the opts map" do
      assert Options.parse_opt_required!(%{a: 1, b: 2}, :b) == 2
    end

    test "raises if opt cannot be found in the opts list" do
      assert_raise RuntimeError, "Missing opt `c`", fn ->
        Options.parse_opt_required!([a: 1, b: 2], :c)
      end
    end

    test "raises if opt cannot be found in the opts map" do
      assert_raise RuntimeError, "Missing opt `c`", fn ->
        Options.parse_opt_required!(%{a: 1, b: 2}, :c)
      end
    end

    test "raise if opts isn't an Enum" do
      message = "Invalid `opts`! It should be an Enum such as [by: \"id\"]."

      assert_raise RuntimeError, message, fn ->
        Options.parse_opt_required!(nil, :a)
      end
    end
  end

  describe "opt_to_list/2" do
    test "returns the opt if it's a list" do
      assert Options.opt_to_list([a: 1, b: 2], :foo) == [a: 1, b: 2]
    end

    test "converts the opt into a list if it's a map" do
      assert Options.opt_to_list(%{a: 1, b: 2}, :foo) == [a: 1, b: 2]
    end

    test "converts the opt into a list with the default_opt_name as the key and opt the value if the opt is not an Enum" do
      assert Options.opt_to_list(42, :foo) == [foo: 42]
    end
  end

  describe "parse_with_default/3" do
    test "gets the opt value if the key exists in the opts list and the value is true" do
      assert Options.parse_with_default([a: true, b: false], :a, :foo)
    end

    test "gets the opt value if the key exists in the opts list and the value is false" do
      refute Options.parse_with_default([a: false, b: true], :a, :foo)
    end

    test "gets the opt value if the key exists in the opts map and the value is true" do
      assert Options.parse_with_default(%{a: true, b: false}, :a, :foo)
    end

    test "gets the opt value if the key exists in the opts map and the value is false" do
      refute Options.parse_with_default(%{a: false, b: true}, :a, :foo)
    end

    test "gets the default value if the key doesn't exist in the opts list" do
      assert Options.parse_with_default([a: true, b: false], :c, :foo) == :foo
    end

    test "gets the default value if the key doesn't exist in the opts map" do
      assert Options.parse_with_default(%{a: true, b: false}, :c, :foo) == :foo
    end
  end

  describe "non_empty_list?/1" do
    test "returns true if it's a list with 1 or more elements" do
      assert Options.non_empty_list?(a: 1, b: 2)
    end

    test "returns false if it's not a list" do
      refute Options.non_empty_list?(nil)
      refute Options.non_empty_list?(:foo)
      refute Options.non_empty_list?(%{})
      refute Options.non_empty_list?(123)
    end

    test "returns false if it's an empty list" do
      refute Options.non_empty_list?([])
    end
  end
end
