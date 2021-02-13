defmodule Barna.Options do
  @moduledoc """
  This module contains functions for parsing the input options for the generated schema functions.
  """

  @spec parse_opt_required!(list | map, term) :: term | no_return
  def parse_opt_required!(opts, opt_name) when is_list(opts) do
    if Keyword.has_key?(opts, opt_name) do
      opts[opt_name]
    else
      raise "Missing opt `#{opt_name}`"
    end
  end

  def parse_opt_required!(%{} = opts, opt_name) do
    if Map.has_key?(opts, opt_name) do
      opts[opt_name]
    else
      raise "Missing opt `#{opt_name}`"
    end
  end

  def parse_opt_required!(_, _) do
    raise("Invalid `opts`! It should be an Enum such as [by: \"id\"].")
  end

  @spec opt_to_list(list | map | term, term) :: [{term, term}]
  def opt_to_list(opt, _default_opt_name) when is_list(opt), do: opt
  def opt_to_list(%{} = opt, _default_opt_name), do: Map.to_list(opt)
  def opt_to_list(opt, default_opt_name), do: [{default_opt_name, opt}]

  @spec parse_with_default(list | map, term, term) :: term
  def parse_with_default(opts, opt_name, default_value) when is_list(opts) do
    if Keyword.has_key?(opts, opt_name) do
      opts[opt_name]
    else
      default_value
    end
  end

  def parse_with_default(%{} = opts, opt_name, default_value) do
    if Map.has_key?(opts, opt_name) do
      opts[opt_name]
    else
      default_value
    end
  end

  @spec non_empty_list?(list | nil) :: boolean
  def non_empty_list?([]), do: false
  def non_empty_list?(list) when is_list(list), do: true
  def non_empty_list?(_), do: false
end
