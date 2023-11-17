defmodule MtgFriends.Repo.Migrations.CreateRounds do
  use Ecto.Migration

  def change do
    create table(:rounds) do
      add :active, :boolean, default: true, null: false
      add :number, :integer, default: 0, null: false
      add :tournament_id, references(:tournaments, on_delete: :delete_all)

      timestamps()
    end

    create index(:rounds, [:tournament_id])
  end
end
