defmodule MtgFriends.Repo.Migrations.CreateTournaments do
  use Ecto.Migration

  def change do
    create table(:tournaments) do
      add :date, :date
      add :name, :string
      add :location, :string
      add :description, :text
      add :standings_raw, :text
      add :active, :boolean, default: true, null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:tournaments, [:user_id])
  end
end
