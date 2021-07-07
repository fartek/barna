defmodule Barna.Query do
  @moduledoc """
  This module contains various functions for manipulating and generating `Ecto.Queryable`s.
  """

  alias Barna.Options

  import Ecto.Query

  @spec parse_include(Ecto.Queryable.t(), list | nil) :: Ecto.Queryable.t()
  def parse_include(query, include) do
    include |> Options.non_empty_list?() |> do_parse_include(query, include)
  end

  @spec do_parse_include(boolean, Ecto.Queryable.t(), list | nil) :: Ecto.Queryable.t()
  defp do_parse_include(true, query, include) do
    Enum.reduce(include, query, fn incl, q ->
      from(schema in q,
        left_join: joined in assoc(schema, ^incl),
        preload: [{^incl, joined}]
      )
    end)
  end

  defp do_parse_include(_, query, _), do: query

  @spec parse_include!(Ecto.Queryable.t(), list | nil) :: Ecto.Queryable.t()
  def parse_include!(query, include!) do
    include! |> Options.non_empty_list?() |> do_parse_include!(query, include!)
  end

  @spec do_parse_include!(boolean, Ecto.Queryable.t(), list | nil) :: Ecto.Queryable.t()
  defp do_parse_include!(true, query, include!) do
    Enum.reduce(include!, query, fn incl, q ->
      from(schema in q,
        inner_join: joined in assoc(schema, ^incl),
        preload: [{^incl, joined}]
      )
    end)
  end

  defp do_parse_include!(_, query, _), do: query

  @spec parse_limit(Ecto.Queryable.t(), nil | non_neg_integer) :: Ecto.Queryable.t()
  def parse_limit(query, nil), do: query
  def parse_limit(query, limit_val), do: limit(query, ^limit_val)
end
