defmodule Barna.Integration.Factory do
  alias Barna.Integration.{Address, Comment, TestRepo, User}

  def insert!(factory_name, attributes \\ []) do
    factory_name |> build(attributes) |> TestRepo.insert!()
  end

  def build(factory_name, attributes) do
    factory_name |> build() |> struct(attributes)
  end

  def build(:user) do
    %User{
      name: "John",
      email: "john@doe.com",
      address: nil,
      comments: []
    }
  end

  def build(:address) do
    %Address{street_name: "Test street"}
  end

  def build(:comment) do
    %Comment{title: "comment title", message: "comment message"}
  end
end
