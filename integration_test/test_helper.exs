alias Barna.Integration.{TestRepo, Migration}

Application.put_env(:barna, TestRepo,
  url: "ecto://postgres:postgres@127.0.0.1/ecto_test",
  pool: Ecto.Adapters.SQL.Sandbox,
  show_sensitive_data_on_connection_error: true
)

Application.put_env(:barna, Barna, repo: TestRepo)

{:ok, _} = Ecto.Adapters.Postgres.ensure_all_started(TestRepo.config(), :temporary)

# Load up the repository, start it, and run migrations
_   = Ecto.Adapters.Postgres.storage_down(TestRepo.config())
:ok = Ecto.Adapters.Postgres.storage_up(TestRepo.config())

{:ok, _pid} = TestRepo.start_link()

:ok = Ecto.Migrator.up(TestRepo, 0, Migration, log: false)
Ecto.Adapters.SQL.Sandbox.mode(TestRepo, :manual)
Process.flag(:trap_exit, true)
