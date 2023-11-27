defmodule MtgFriends.Repo.Migrations.AddTypesToTournament do
  use Ecto.Migration

  def change do
    alter table(:tournaments) do
      add :format, :string, default: "edh"
      add :subformat, :string
      add :top_cut_4, :boolean, default: false
    end
  end
end
