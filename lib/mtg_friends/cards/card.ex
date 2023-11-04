defmodule MtgFriends.Cards.Card do
  use Ecto.Schema
  import Ecto.Changeset

  schema "cards" do
    field :name, :string
    field :type, :string
    field :keywords, {:array, :string}
    field :colors, {:array, :string}
    field :scryfall_id, :string
    field :scryfall_uri, :string
    field :lang, :string
    field :image_uri_default, :string
    field :mana_cost, :string
    field :cmc, :integer
    field :power, :string
    field :toughness, :string
    field :release_date, :date
    field :oracle_text, :string
    field :set_code, :string
    field :set_name, :string
    field :color_identity, {:array, :string}

    timestamps()
  end

  @doc false
  def changeset(card, attrs) do
    card
    |> cast(attrs, [:name, :scryfall_id, :scryfall_uri, :lang, :image_uri_default, :mana_cost, :cmc, :power, :toughness, :release_date, :type, :oracle_text, :set_code, :set_name, :keywords, :colors, :color_identity])
    |> validate_required([:name, :scryfall_id, :scryfall_uri, :lang, :image_uri_default, :mana_cost, :cmc, :power, :toughness, :release_date, :type, :oracle_text, :set_code, :set_name, :keywords, :colors, :color_identity])
  end
end
