defmodule Barna.Fetch.RepoNotFound do
  def one(query) do
    send(self(), {:fetch_repo_not_found, query})
    nil
  end
end
