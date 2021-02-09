defmodule Barna do
  @moduledoc """
  This module contains all of the macro magic that ultimately generates the additional functions
  in the schemas that `use` it.

  Functions that are added to schemas:
  - fetch/1
  """

  import Ecto.Query

  defmacro __using__(_) do
    quote do
      use Ecto.Schema

      import Ecto.Query

      @before_compile Barna
    end
  end

  defmacro __before_compile__(env) do
    properties =
      env.module
      |> Module.get_attribute(:ecto_fields)
      |> Enum.map(fn {key, _} -> key end)

    fallback_case =
      quote do
        {key, val}, _dynamic ->
          raise "Trying to match on property '#{key}' with val '#{val}' on '#{__MODULE__}' but the property doesn't exist"
      end

    where_cases =
      Enum.flat_map(properties, fn property ->
        quote do
          {unquote(property), value}, dynamic ->
            dynamic(
              [schema],
              ^dynamic and
                unquote({{:., [], [{:schema, [], Elixir}, property]}, [no_parens: true], []}) ==
                  ^value
            )
        end
      end) ++ fallback_case

    reducer = {:fn, [], quote(do: unquote(where_cases))}

    quote do
      @type fetch_opt ::
              {:by, term} | {:include, [atom]} | {:include!, [atom]} | {:result_as_tuple, boolean}
      @spec fetch([fetch_opt]) :: struct | nil | {:ok, struct} | {:error, :not_found}
      def fetch(opts) do
        #######################
        #   Prepare the opts  #
        #######################
        by = Barna.Options.parse_opt_required!(opts, :by) |> Barna.Options.opt_to_list(:id)
        result_as_tuple = Barna.Options.parse_boolean_opt(opts, :result_as_tuple, true)

        include = opts[:include]
        include! = opts[:include!]

        ############################
        #   Generate the queries   #
        ############################
        where_params = Enum.reduce(by, dynamic(true), unquote(reducer))

        query =
          __MODULE__
          |> where(^where_params)
          |> Barna.Query.parse_include(include)
          |> Barna.Query.parse_include!(include!)

        ####################################
        #   Fetch and return the results   #
        ####################################
        if result_as_tuple do
          Barna.fetch_as_tuple(query)
        else
          Barna.fetch(query)
        end
      end
    end
  end

  @spec fetch(Ecto.Queryable.t()) :: nil | struct
  def fetch(query) do
    repo_module = Application.get_env(:barna, Barna)[:repo]
    repo_module.one(query)
  end

  @spec fetch_as_tuple(Ecto.Queryable.t()) :: {:ok, struct} | {:error, :not_found}
  def fetch_as_tuple(query) do
    case fetch(query) do
      nil -> {:error, :not_found}
      result -> {:ok, result}
    end
  end
end
