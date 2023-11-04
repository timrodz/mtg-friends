defmodule MtgFriends.Repo.Migrations.CreateCards do
  use Ecto.Migration

  def change do
    create table(:cards) do
      add :name, :string
      add :scryfall_id, :string
      add :scryfall_uri, :string
      add :lang, :string
      add :image_uri_default, :string
      add :mana_cost, :string
      add :cmc, :integer
      add :power, :string
      add :toughness, :string
      add :release_date, :date
      add :type, :string
      add :oracle_text, :string
      add :set_code, :string
      add :set_name, :string
      add :keywords, {:array, :string}
      add :colors, {:array, :string}
      add :color_identity, {:array, :string}

      timestamps()
    end
  end
end
