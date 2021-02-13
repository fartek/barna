defmodule Barna.Fetch.RepoFound do
  def one(query) do
    send(self(), {:fetch_repo_found, query})
    :result
  end
end
