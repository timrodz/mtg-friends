defmodule MtgFriends.Repo.Migrations.CreatePairings do
  use Ecto.Migration

  def change do
    create table(:pairings) do
      add :winner, :boolean, default: false, null: false
      add :active, :boolean, default: true, null: false
      add :number, :integer, default: 0, null: false
      add :points, :integer, default: 0, null: false
      add :tournament_id, references(:tournaments, on_delete: :delete_all)
      add :round_id, references(:rounds, on_delete: :delete_all)
      add :participant_id, references(:participants, on_delete: :delete_all)

      timestamps()
    end

    create index(:pairings, [:tournament_id])
    create index(:pairings, [:round_id])
    create index(:pairings, [:participant_id])
  end
end
