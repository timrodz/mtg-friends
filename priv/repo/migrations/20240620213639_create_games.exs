defmodule MtgFriends.Repo.Migrations.CreateGames do
  use Ecto.Migration

  alias MtgFriends.Games.Game
  alias MtgFriends.Repo
  alias Ecto.Query

  def change do
    create table(:games) do
      add :name, :string
      add :code, :string, default: "mtg"
      add :url, :string

      timestamps()
    end

    create index(:games, [:code])
  end
end
