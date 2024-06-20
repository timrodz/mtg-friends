defmodule MtgFriends.Repo.Migrations.AddIsDroppedToParticipants do
  use Ecto.Migration

  def change do
    alter table(:participants) do
      add :is_dropped, :boolean, default: false
    end
  end
end
