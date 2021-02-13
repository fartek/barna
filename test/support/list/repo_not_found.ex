defmodule Barna.List.RepoNotFound do
  def all(query) do
    send(self(), {:list_repo_not_found, query})
    []
  end
end
