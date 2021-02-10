# Barna

Extends your Ecto schemas with convenience functions so that you can focus on your domain logic instead of plumbing.

## Adds the following functions
### fetch/1
Allows you to get one or zero entries from your database. It supports fetching by one or more schema attributes and efficiently joining and preloading (non-nested) associations.

#### Examples

```elixir
# Get by id
MyApp.Accounts.User.fetch(by: "07949870-7d31-48cc-8883-ce882760759f")
# > {:ok, %User{id: "07949870-7d31-48cc-8883-ce882760759f", ...}}

# Get by name AND age
MyApp.Accounts.User.fetch(by: [name: "John", age: 33])
# > {:ok, %User{name: "John", age: 33, ...}}

# If not found returns an error tuple
MyApp.Accounts.User.fetch(by: [email: "non-existing@example.com"])
# > {:error, :not_found}

# Get by id and include the Foo association (via left join)
MyApp.Accounts.User.fetch(by: "07949870-7d31-48cc-8883-ce882760759f", include: [:foo])
# > {:ok, %User{id: "07949870-7d31-48cc-8883-ce882760759f", foo: %Foo{bar: "baz"}}}

# Get by id and include the Foo association (via inner join)
MyApp.Accounts.User.fetch(by: "07949870-7d31-48cc-8883-ce882760759f", include!: [:foo])
# > {:ok, %User{id: "07949870-7d31-48cc-8883-ce882760759f", foo: %Foo{bar: "baz"}}}
```

Note: the `include` and `include!` work via DB joins so everything is just 1 `SELECT` SQL query.

```sql
SELECT u0."id", u0."email", u0."name", u0."inserted_at", u0."updated_at", f1."bar", f1."inserted_at", f1."updated_at" FROM "users" AS u0 LEFT OUTER JOIN "foos" AS f1 ON f1."user_id" = u0."id" WHERE (TRUE AND (u0."id" = $1)) [<<7, 148, 152, 112, 125, 49, 72, 204, 136, 131, 206, 136, 39, 96, 117, 159>>]
```

## I thought I was supposed to use context modules for these kind of things
I found myself writing a lot of context modules that look like this:

```elixir
defmodule MyApp.Accounts do
  def fetch_user(id) do
    User
    |> where([u], u.id == ^id)
    |> join(:left, [u], _ in assoc(u, :foo_asoc))
    |> preload([_, fa], [foo_asoc: fa])
    |> Repo.one
  end

  def fetch_user_by_email(email) do
    Repo.get_by(User, email: email)
  end

  # ...
end
```

These are relatively small and simple functions but you still have to test them. *You DO test your functions, right*? The number of tests rises exponentially when you add a happy path and a few sad/error paths. Barna takes care of these simple functions for you.

**If your functions need to do something more than a basic select query you should still write a custom function in your context module and use that.**


## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `barna` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:barna, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/barna](https://hexdocs.pm/barna).
