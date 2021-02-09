defmodule Barna.Integration.FetchTest do
  use Barna.DataCase, async: true

  alias Barna.Integration.Factory
  alias Barna.Integration.User

  import ExUnit.CaptureLog

  @uuid "00000000-0000-0000-0000-000000000000"

  describe "fetch/1" do
    test "returns an ok-tuple by default if a match is found" do
      user = Factory.insert!(:user)

      assert {:ok, result} = User.fetch(by: user.id)
      assert result.id == user.id
      assert result.name == user.name
      assert result.email == user.email
    end

    test "returns {:error, :not_found} by default if no entries are found" do
      Factory.insert!(:user)
      assert User.fetch(by: @uuid) == {:error, :not_found}
    end

    test "returns the result directly if a match is found and the `result_as_tuple` option is `false`" do
      user = Factory.insert!(:user)

      assert result = User.fetch(by: user.id, result_as_tuple: false)
      assert result.id == user.id
      assert result.name == user.name
      assert result.email == user.email
    end

    test "returns nil if no entries are found and the `result_as_tuple` option is `false`" do
      Factory.insert!(:user)
      assert is_nil(User.fetch(by: @uuid, result_as_tuple: false))
    end
  end

  describe "the `:by` option" do
    test "is required" do
      assert_raise RuntimeError, "Missing opt `by`", fn ->
        User.fetch([])
      end
    end

    test "can search by a list of properties" do
      Factory.insert!(:user, name: "John", email: "john@doe.com")

      assert {:ok, _user} = User.fetch(by: [name: "John", email: "john@doe.com"])
      assert User.fetch(by: [name: "John", email: "invalid@email.com"]) == {:error, :not_found}
    end

    test "defaults to `id` if the type is not a list" do
      user = Factory.insert!(:user)

      assert User.fetch(by: user.id) == User.fetch(by: [id: user.id])
    end

    test "raises if the property does not exist on the schema" do
      message = "Trying to match on property 'invalid' with val 'foo' on 'Elixir.Barna.Integration.User' but the property doesn't exist"
      assert_raise RuntimeError, message, fn ->
        User.fetch(by: [invalid: "foo"])
      end
    end

    test "generates a SELECT statement which selects by the specified property" do
      log_id = capture_log(fn ->
        User.fetch(by: @uuid)
      end)

      log_email = capture_log(fn ->
        User.fetch(by: [email: "john@doe.com"])
      end)

      assert [_] = Regex.scan(~r/SELECT.+WHERE.+u0\.\"id\" = \$\d/, log_id)
      assert [_] = Regex.scan(~r/SELECT.+WHERE.+u0\.\"email\" = \$\d/, log_email)
    end
  end

  describe "the `:include` option" do
    test "preloads one or more specified associations" do
      user = Factory.insert!(:user)
      address = Factory.insert!(:address, user_id: user.id)
      comment_1 = Factory.insert!(:comment, user_id: user.id)
      comment_2 = Factory.insert!(:comment, user_id: user.id)

      assert {:ok, result} = User.fetch(by: user.id, include: [:address, :comments])
      assert result.id == user.id
      assert result.address.id == address.id
      assert Enum.map(result.comments, & &1.id) == [comment_1.id, comment_2.id]
    end

    test "fails if the association doesn't exist in the schema" do
      user = Factory.insert!(:user)

      error_message = ~r/could not find association `invalid` on schema Barna.Integration.User in query/
      assert_raise Ecto.QueryError, error_message, fn ->
        User.fetch(by: user.id, include: [:invalid])
      end
    end

    test "still returns the ok-tuple even if none of the included association(s) are found" do
      user = Factory.insert!(:user)
      assert {:ok, result} = User.fetch(by: user.id, include: [:address, :comments])
      assert is_nil(result.address)
      assert result.comments == []
    end

    test "generates an efficient `join` instead of doing multiple `select` statements" do
      log = capture_log(fn ->
        User.fetch(by: @uuid, include: [:address, :comments])
      end)

      assert Regex.scan(~r/SELECT/, log) == [["SELECT"]]
      assert Regex.scan(~r/LEFT OUTER JOIN/, log) == [["LEFT OUTER JOIN"], ["LEFT OUTER JOIN"]]
    end
  end

  describe "the `:include!` option" do
    test "preloads one or more specified associations" do
      user = Factory.insert!(:user)
      address = Factory.insert!(:address, user_id: user.id)
      comment_1 = Factory.insert!(:comment, user_id: user.id)
      comment_2 = Factory.insert!(:comment, user_id: user.id)

      assert {:ok, result} = User.fetch(by: user.id, include!: [:address, :comments])
      assert result.id == user.id
      assert result.address.id == address.id
      assert Enum.map(result.comments, & &1.id) == [comment_1.id, comment_2.id]
    end

    test "fails if the association doesn't exist on the schema" do
      user = Factory.insert!(:user)

      error_message = ~r/could not find association `invalid` on schema Barna.Integration.User in query/
      assert_raise Ecto.QueryError, error_message, fn ->
        User.fetch(by: user.id, include: [:invalid])
      end
    end

    test "returns {:error, :not_found} if at least one of the included! associations are not found" do
      # User with address and without any comments
      user = Factory.insert!(:user)
      Factory.insert!(:address, user_id: user.id)
      
      assert {:ok, _} = User.fetch(by: user.id, include!: [:address])
      assert User.fetch(by: user.id, include!: [:comments]) == {:error, :not_found}
      assert User.fetch(by: user.id, include!: [:address, :comments]) == {:error, :not_found}

      # User with comments but without an address
      user = Factory.insert!(:user)
      Factory.insert!(:comment, user_id: user.id)

      assert {:ok, _} = User.fetch(by: user.id, include!: [:comments])
      assert User.fetch(by: user.id, include!: [:address]) == {:error, :not_found}
      assert User.fetch(by: user.id, include!: [:address, :comments]) == {:error, :not_found}
    end

    test "generates an efficient `join` instead of doing multiple `select` statements" do
      log = capture_log(fn ->
        User.fetch(by: @uuid, include!: [:address, :comments])
      end)

      assert Regex.scan(~r/SELECT/, log) == [["SELECT"]]
      assert Regex.scan(~r/INNER JOIN/, log) == [["INNER JOIN"], ["INNER JOIN"]]
    end
  end
end
