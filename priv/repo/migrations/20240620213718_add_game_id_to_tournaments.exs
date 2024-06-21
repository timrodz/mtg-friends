defmodule MtgFriends.Repo.Migrations.AddGameIdToTournaments do
  use Ecto.Migration

  alias MtgFriends.Tournaments.Tournament

  def change do
    alter table(:tournaments) do
      add :game_id, references(:games, on_delete: :nothing)
    end

    create index(:tournaments, [:game_id])
  end
end
