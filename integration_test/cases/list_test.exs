defmodule Barna.Integration.ListTest do
  use Barna.DataCase, async: true

  alias Barna.Integration.Factory
  alias Barna.Integration.User

  import ExUnit.CaptureLog

  @uuid "00000000-0000-0000-0000-000000000000"

  describe "list/1" do
    test "returns a list of entries" do
      user = Factory.insert!(:user, name: "John", inserted_at: ~N[2021-01-01 01:01:01])

      assert results = User.list()
      assert [user.id] == Enum.map(results, & &1.id)
    end

    test "returns an empty list if no entries are found" do
      assert User.list() == []
    end

    test "returns a list ordered by inserted_at (asc) by default" do
      user_1 = Factory.insert!(:user, name: "John", inserted_at: ~N[2021-01-01 01:01:01])
      user_2 = Factory.insert!(:user, name: "John", inserted_at: ~N[2021-01-01 02:02:02])
      user_3 = Factory.insert!(:user, name: "John", inserted_at: ~N[2021-01-01 02:02:02])

      assert results = User.list()
      assert [user_1.id, user_2.id, user_3.id] == Enum.map(results, & &1.id)
    end
  end

  describe "the `:by` option" do
    test "can search by a list of properties" do
      Factory.insert!(:user, name: "John", email: "john@doe.com")
      Factory.insert!(:user, name: "John", email: "john@doe.com")

      assert [_, _] = User.list(by: [name: "John", email: "john@doe.com"])
      assert User.list(by: [name: "John", email: "invalid@email.com"]) == []
    end

    test "defaults to `id` if the type is not a list" do
      user = Factory.insert!(:user)

      assert User.list(by: user.id) == User.list(by: [id: user.id])
    end

    test "raises if the property does not exist on the schema" do
      message = "Trying to match on property 'invalid' with val 'foo' on 'Elixir.Barna.Integration.User' but the property doesn't exist"
      assert_raise RuntimeError, message, fn ->
        User.list(by: [invalid: "foo"])
      end
    end

    test "generates a SELECT statement which selects by the specified property" do
      log_id = capture_log(fn ->
        User.list(by: @uuid)
      end)

      log_email = capture_log(fn ->
        User.list(by: [email: "john@doe.com"])
      end)

      assert [_] = Regex.scan(~r/SELECT.+WHERE.+u0\.\"id\" = \$\d/, log_id)
      assert [_] = Regex.scan(~r/SELECT.+WHERE.+u0\.\"email\" = \$\d/, log_email)
    end
  end

  describe "the `:include` option" do
    test "preloads one or more specified associations" do
      user = Factory.insert!(:user, inserted_at: ~N[2021-01-01 01:01:01])
      address = Factory.insert!(:address, user_id: user.id)
      comment = Factory.insert!(:comment, user_id: user.id)

      user_2 = Factory.insert!(:user, inserted_at: ~N[2021-01-01 02:02:02])
      address_2 = Factory.insert!(:address, user_id: user_2.id)
      comment_2 = Factory.insert!(:comment, user_id: user_2.id)

      assert [result_1, result_2] = User.list(include: [:address, :comments])
      assert result_1.id == user.id
      assert result_2.id == user_2.id
      assert result_1.address.id == address.id
      assert result_2.address.id == address_2.id
      assert Enum.map(result_1.comments, & &1.id) == [comment.id]
      assert Enum.map(result_2.comments, & &1.id) == [comment_2.id]
    end

    test "fails if the association doesn't exist in the schema" do
      error_message = ~r/could not find association `invalid` on schema Barna.Integration.User in query/
      assert_raise Ecto.QueryError, error_message, fn ->
        User.list(include: [:invalid])
      end
    end

    test "still returns matched results even if none of the included association(s) are found" do
      Factory.insert!(:user)
      assert [result] = User.list(include: [:address, :comments])
      assert is_nil(result.address)
      assert result.comments == []
    end

    test "generates an efficient `join` instead of doing multiple `select` statements" do
      log = capture_log(fn ->
        User.list(include: [:address, :comments])
      end)

      assert Regex.scan(~r/SELECT/, log) == [["SELECT"]]
      assert Regex.scan(~r/LEFT OUTER JOIN/, log) == [["LEFT OUTER JOIN"], ["LEFT OUTER JOIN"]]
    end
  end

  describe "the `:include!` option" do
    test "preloads one or more specified associations" do
      user = Factory.insert!(:user, inserted_at: ~N[2021-01-01 01:01:01])
      address = Factory.insert!(:address, user_id: user.id)
      comment = Factory.insert!(:comment, user_id: user.id)

      user_2 = Factory.insert!(:user, inserted_at: ~N[2021-01-01 02:02:02])
      address_2 = Factory.insert!(:address, user_id: user_2.id)
      comment_2 = Factory.insert!(:comment, user_id: user_2.id)

      assert [result_1, result_2] = User.list(include!: [:address, :comments])
      assert result_1.id == user.id
      assert result_2.id == user_2.id
      assert result_1.address.id == address.id
      assert result_2.address.id == address_2.id
      assert Enum.map(result_1.comments, & &1.id) == [comment.id]
      assert Enum.map(result_2.comments, & &1.id) == [comment_2.id]
    end

    test "fails if the association doesn't exist on the schema" do
      error_message = ~r/could not find association `invalid` on schema Barna.Integration.User in query/
      assert_raise Ecto.QueryError, error_message, fn ->
        User.list(include: [:invalid])
      end
    end

    test "only returns entries where all included! associations exist" do
      # User with an address and without any comments
      user_with_address = Factory.insert!(:user, inserted_at: ~N[2021-01-01 01:01:01])
      user_with_address_id = user_with_address.id
      Factory.insert!(:address, user_id: user_with_address.id)

      # User with comments but without an address
      user_with_comments = Factory.insert!(:user, inserted_at: ~N[2021-01-01 02:02:02])
      user_with_comments_id = user_with_comments.id
      Factory.insert!(:comment, user_id: user_with_comments.id)

      # User with both comments AND an address
      user_with_both = Factory.insert!(:user, inserted_at: ~N[2021-01-01 03:03:03])
      user_with_both_id = user_with_both.id
      Factory.insert!(:comment, user_id: user_with_both.id)
      Factory.insert!(:address, user_id: user_with_both.id)

      # User with no associations
      _user_with_none = Factory.insert!(:user, inserted_at: ~N[2021-01-01 04:04:04])
      
      assert [%{id: ^user_with_address_id}, %{id: ^user_with_both_id}] = User.list(include!: [:address])
      assert [%{id: ^user_with_comments_id}, %{id: ^user_with_both_id}] = User.list(include!: [:comments])
      assert [%{id: ^user_with_both_id}] = User.list(include!: [:address, :comments])
    end

    test "generates an efficient `join` instead of doing multiple `select` statements" do
      log = capture_log(fn ->
        User.list(include!: [:address, :comments])
      end)

      assert Regex.scan(~r/SELECT/, log) == [["SELECT"]]
      assert Regex.scan(~r/INNER JOIN/, log) == [["INNER JOIN"], ["INNER JOIN"]]
    end
  end

  describe "the `:order_by` option" do
    test "is [asc: :inserted_at] by default" do
      user_1 = Factory.insert!(:user, inserted_at: ~N[2021-01-01 02:02:02])
      user_2 = Factory.insert!(:user, inserted_at: ~N[2021-01-01 01:01:01])

      assert [result_1, result_2] = User.list()
      assert result_1.id == user_2.id
      assert result_2.id == user_1.id
    end

    test "is [asc: property_name] when just the property_name is provided" do
      user_1 = Factory.insert!(:user, name: "Beta", inserted_at: ~N[2021-01-01 01:01:01])
      user_2 = Factory.insert!(:user, name: "Alpha", inserted_at: ~N[2021-01-01 02:02:02])

      assert [result_1, result_2] = User.list(order_by: :name)
      assert result_1.id == user_2.id
      assert result_2.id == user_1.id
    end

    test "orders by exactly what the input param says" do
      user_1 = Factory.insert!(:user, name: "Beta", inserted_at: ~N[2021-01-01 02:02:02])
      user_2 = Factory.insert!(:user, name: "Beta", inserted_at: ~N[2021-01-01 01:01:01])
      user_3 = Factory.insert!(:user, name: "Alpha", inserted_at: ~N[2021-01-01 03:03:03])
      user_4 = Factory.insert!(:user, name: "Alpha", inserted_at: ~N[2021-01-01 04:04:04])

      assert [result_1, result_2, result_3, result_4] = User.list(order_by: [desc: :name, asc: :inserted_at])
      assert result_1.id == user_2.id
      assert result_2.id == user_1.id
      assert result_3.id == user_3.id
      assert result_4.id == user_4.id
    end
  end
end
