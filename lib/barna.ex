defmodule Barna do
  defmacro __using__(_) do
    quote do
      use Ecto.Schema

      import Ecto.Query

      @before_compile Barna
    end
  end

  defmacro __before_compile__(env) do
    properties = env.module
    |> Module.get_attribute(:ecto_fields)
    |> Enum.map(fn {key, _} -> key end)

    fallback_case_error = quote do: ({key, val}, _dynamic -> raise "Trying to match on property '#{key}' with val '#{val}' on '#{__MODULE__}' but the property doesn't exist")
    fallback_case_ignore = quote do: ({key, val}, dynamic -> dynamic)

    where_quote = Enum.flat_map(properties, fn property ->
      quote do
        {unquote(property), value}, dynamic -> dynamic([schema], ^dynamic and unquote({{:., [], [{:schema, [], Elixir}, property]}, [no_parens: true], []}) == ^value)
      end
    end)
    where_quote_error = where_quote ++ fallback_case_error
    where_quote_ignore = where_quote ++ fallback_case_ignore

    reducer = {:fn, [], quote do: unquote(where_quote_ignore)}
    reducer! = {:fn, [], quote do: unquote(where_quote_error)}

    quote do
      def apply_filters(filters) do
        Enum.reduce(filters, dynamic(true), unquote(reducer))
      end

      def apply_filters!(filters) do
        Enum.reduce(filters, dynamic(true), unquote(reducer!))
      end

      def fetch(opts) do
        by = opts[:by] || raise "Missing opt 'by'"
        include = opts[:include] # left join
        include! = opts[:include!] # inner join

        by = case by do
          by when is_atom(by) -> [id: by]
          by when is_binary(by) -> [id: by]
          by when is_list(by) -> by
        end

        where_params = __MODULE__.apply_filters!(by)
        query = __MODULE__ |> where(^where_params)

        query = if !is_nil(include) && include != [] do
          Enum.reduce(include, query, fn incl, q ->
            from schema in q,
            left_join: joined in assoc(schema, ^incl),
            preload: [{^incl, joined}]
          end)
        else
          query
        end

        query = if !is_nil(include!) && include! != [] do
          Enum.reduce(include!, query, fn incl, q ->
            from schema in q,
            inner_join: joined in assoc(schema, ^incl),
            preload: [{^incl, joined}]
          end)
        else
          query
        end

        repo_module = Application.get_env(:barna, Barna)[:repo]

        case repo_module.one(query) do
          nil -> {:error, :not_found}
          result -> {:ok, result}
        end
      end
    end
  end
end
