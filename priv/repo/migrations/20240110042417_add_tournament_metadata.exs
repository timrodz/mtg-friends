defmodule MtgFriends.Repo.Migrations.AddTopCut4ToRounds do
  use Ecto.Migration

  def change do
    alter table(:participants) do
      add :is_winner, :boolean, default: false
    end

    alter table(:rounds) do
      add :is_top_cut_4, :boolean, default: false
    end
  end
end
