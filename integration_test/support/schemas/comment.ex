defmodule Barna.Integration.Comment do
  use Barna.Integration.Schema

  schema "comments" do
    field :title, :string
    field :message, :string

    belongs_to :user, Barna.Integration.User

    timestamps()
  end
end
