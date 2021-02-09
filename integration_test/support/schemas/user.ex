defmodule Barna.Integration.User do
  use Barna.Integration.Schema

  schema "users" do
    field :name, :string
    field :email, :string

    has_one :address, Barna.Integration.Address
    has_many :comments, Barna.Integration.Comment

    timestamps()
  end
end
