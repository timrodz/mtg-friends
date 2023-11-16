defmodule MtgFriends.Repo.Migrations.CreateParticipants do
  use Ecto.Migration

  def change do
    create table(:participants) do
      add :name, :string
      add :points, :integer
      add :decklist, :string
      add :tournament_id, references(:tournaments, on_delete: :nothing)

      timestamps()
    end

    create index(:participants, [:tournament_id])
  end
end
