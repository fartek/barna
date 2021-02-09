defmodule Barna.Integration.Address do
  use Barna.Integration.Schema

  schema "addresses" do
    field :street_name, :string

    belongs_to :user, Barna.Integration.User

    timestamps()
  end
end
