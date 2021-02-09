defmodule Barna.DataCase do
  use ExUnit.CaseTemplate

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Barna.Integration.TestRepo)
  end
end
