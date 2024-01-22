defmodule MtgFriends.Repo.Migrations.AddTournamentDateTime do
  use Ecto.Migration

  def change do
    alter table(:tournaments) do
      modify :date, :naive_datetime
    end
  end
end
