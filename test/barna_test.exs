defmodule BarnaTest do
  use ExUnit.Case, async: false

  defmodule FakeRepoFound do
    def one(query) do
      send(self(), {:fake_repo_found_one, query})
      :result
    end
  end

  defmodule FakeRepoNotFound do
    def one(query) do
      send(self(), {:fake_repo_not_found_one, query})
      nil
    end
  end

  describe "fetch/1" do
    test "calls Repo.one with the query and returns the result if it's found" do
      Application.put_env(:barna, Barna, repo: FakeRepoFound)

      assert Barna.fetch(:query) == :result
      assert_received {:fake_repo_found_one, :query}
    end

    test "calls Repo.one with the query and returns nil if it's not found" do
      Application.put_env(:barna, Barna, repo: FakeRepoNotFound)

      assert is_nil(Barna.fetch(:query))
      assert_received {:fake_repo_not_found_one, :query}
    end
  end

  describe "fetch_as_tuple/1" do
    test "calls Repo.one with the query and returns an ok tuple if it's found" do
      Application.put_env(:barna, Barna, repo: FakeRepoFound)

      assert Barna.fetch_as_tuple(:query) == {:ok, :result}
      assert_received {:fake_repo_found_one, :query}
    end

    test "calls Repo.one with the query and returns an error tuple it's not found" do
      Application.put_env(:barna, Barna, repo: FakeRepoNotFound)

      assert Barna.fetch_as_tuple(:query) == {:error, :not_found}
      assert_received {:fake_repo_not_found_one, :query}
    end
  end
end
