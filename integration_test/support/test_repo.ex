defmodule Barna.Integration.TestRepo do
  use Ecto.Repo, otp_app: :barna, adapter: Ecto.Adapters.Postgres
end
