defmodule Barna.List.RepoFound do
  def all(query) do
    send(self(), {:list_repo_found, query})
    [:result]
  end
end
