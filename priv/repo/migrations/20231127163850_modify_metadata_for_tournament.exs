defmodule MtgFriends.Repo.Migrations.ModifyMetadataForTournament do
  use Ecto.Migration

  def up do
    alter table(:tournaments) do
      add :status, :string, default: "inactive"
      add :round_length_minutes, :integer, default: 60
      modify :format, :string, default: "edh"
      modify :subformat, :string, default: "bubble_rounds"
      remove :active
      remove :standings_raw
    end
  end

  def down do
    alter table(:tournaments) do
      remove :status
      remove :round_length_minutes
      modify :format, :string, default: "edh"
      modify :subformat, :string, default: "bubble_rounds"
      add :active, :boolean
      add :standings_raw, :string
    end
  end
end
