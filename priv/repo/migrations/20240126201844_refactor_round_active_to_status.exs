defmodule MtgFriends.Repo.Migrations.RefactorRoundActiveToStatus do
  use Ecto.Migration

  def up do
    alter table(:rounds) do
      add :status, :string, default: "inactive"
      add :started_at, :naive_datetime
      remove :active
    end
  end

  def down do
    alter table(:rounds) do
      add :active, :boolean, default: true, null: false
      remove :started_at
      remove :status
    end
  end
end
