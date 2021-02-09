defmodule Barna.QueryTest do
  use ExUnit.Case, async: true

  alias Barna.Query
  alias Barna.Integration.User

  import Ecto.Query

  describe "parse_include/2" do
    test "returns the original query if no include specified" do
      assert Query.parse_include(User, nil) == User
    end

    test "returns the original query if include is an empty list" do
      assert Query.parse_include(User, []) == User
    end

    test "left joins the included associations and preloads them" do
      expected_query =
        from(u in User,
          left_join: a in assoc(u, :address),
          left_join: c in assoc(u, :comments),
          preload: [comments: c, address: a]
        )

      query = Query.parse_include(User, [:address, :comments])
      assert queries_equal?(query, expected_query)
    end

    test "left joins and preloads even invalid assoiations" do
      expected_query =
        from(u in User,
          left_join: i in assoc(u, :invalid),
          preload: [invalid: i]
        )

      query = Query.parse_include(User, [:invalid])
      assert queries_equal?(query, expected_query)
    end
  end

  describe "parse_include!/2" do
    test "returns the original query if no include! specified" do
      assert Query.parse_include!(User, nil) == User
    end

    test "returns the original query if include! is an empty list" do
      assert Query.parse_include!(User, []) == User
    end

    test "inner joins the included! associations and preloads them" do
      expected_query =
        from(u in User,
          join: a in assoc(u, :address),
          join: c in assoc(u, :comments),
          preload: [comments: c, address: a]
        )

      query = Query.parse_include!(User, [:address, :comments])
      assert queries_equal?(query, expected_query)
    end

    test "left joins and preloads even invalid assoiations" do
      expected_query =
        from(u in User,
          join: i in assoc(u, :invalid),
          preload: [invalid: i]
        )

      query = Query.parse_include!(User, [:invalid])
      assert queries_equal?(query, expected_query)
    end
  end

  defp queries_equal?(query_1, query_2) do
    sanitize_query_for_comparison(query_1) == sanitize_query_for_comparison(query_2)
  end

  defp sanitize_query_for_comparison(query) do
    joins =
      Enum.map(query.joins, fn join ->
        %Ecto.Query.JoinExpr{join | file: nil, line: nil, on: nil}
      end)

    %Ecto.Query{query | joins: joins}
  end
end
