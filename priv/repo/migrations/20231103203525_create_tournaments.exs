defmodule MtgFriends.Repo.Migrations.CreateTournaments do
  use Ecto.Migration

  def change do
    create table(:tournaments) do
      add :date, :date, null: false
      add :name, :string, null: false
      add :location, :string, null: false
      add :description_raw, :text
      add :description_html, :text
      add :standings_raw, :text
      add :active, :boolean, default: true, null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:tournaments, [:user_id])
  end
end
