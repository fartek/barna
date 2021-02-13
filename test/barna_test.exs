defmodule BarnaTest do
  use ExUnit.Case, async: false

  describe "fetch/1" do
    test "calls Repo.one with the query and returns the result if it's found" do
      Application.put_env(:barna, Barna, repo: Barna.Fetch.RepoFound)

      assert Barna.fetch(:query) == :result
      assert_received {:fetch_repo_found, :query}
    end

    test "calls Repo.one with the query and returns nil if it's not found" do
      Application.put_env(:barna, Barna, repo: Barna.Fetch.RepoNotFound)

      assert is_nil(Barna.fetch(:query))
      assert_received {:fetch_repo_not_found, :query}
    end
  end

  describe "fetch_as_tuple/1" do
    test "calls Repo.one with the query and returns an ok tuple if it's found" do
      Application.put_env(:barna, Barna, repo: Barna.Fetch.RepoFound)

      assert Barna.fetch_as_tuple(:query) == {:ok, :result}
      assert_received {:fetch_repo_found, :query}
    end

    test "calls Repo.one with the query and returns an error tuple it's not found" do
      Application.put_env(:barna, Barna, repo: Barna.Fetch.RepoNotFound)

      assert Barna.fetch_as_tuple(:query) == {:error, :not_found}
      assert_received {:fetch_repo_not_found, :query}
    end
  end

  describe "list/1" do
    test "calls Repo.all with the query and returns the resulting list" do
      Application.put_env(:barna, Barna, repo: Barna.List.RepoFound)

      assert Barna.list(:query) == [:result]
      assert_received {:list_repo_found, :query}
    end

    test "calls Repo.all with the query and returns an empty list if no matches are found" do
      Application.put_env(:barna, Barna, repo: Barna.List.RepoNotFound)

      assert Barna.list(:query) == []
      assert_received {:list_repo_not_found, :query}
    end
  end
end
