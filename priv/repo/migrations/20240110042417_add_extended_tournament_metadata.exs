defmodule MtgFriends.Repo.Migrations.AddExtendedTournamentMetadata do
  use Ecto.Migration

  def up do
    alter table(:participants) do
      add :is_tournament_winner, :boolean, default: false
    end

    alter table(:tournaments) do
      remove :top_cut_4
      add :is_top_cut_4, :boolean, default: false
      add :round_count, :integer, default: 4
    end
  end

  def down do
    alter table(:participants) do
      remove :is_tournament_winner
    end

    alter table(:tournaments) do
      add :top_cut_4, :boolean, default: false
      remove :is_top_cut_4
      remove :round_count
    end
  end
end
