defmodule Barna.Integration.Migration do
  use Ecto.Migration

  def change do
    create table(:users, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :name, :string
      add :email, :string

      timestamps()
    end
    
    create table(:addresses, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :street_name, :string
      add :user_id, references(:users, type: :binary_id)

      timestamps()
    end

    create table(:comments, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :title, :string
      add :message, :string
      add :user_id, references(:users, type: :binary_id)

      timestamps()
    end
  end
end
