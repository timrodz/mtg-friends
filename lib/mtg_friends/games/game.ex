defmodule MtgFriends.Games.Game do
  use Ecto.Schema
  import Ecto.Changeset

  schema "games" do
    field :name, :string
    field :code, Ecto.Enum, values: [:mtg, :yugioh, :pokemon], default: :mtg
    field :url, :string

    timestamps()
  end

  @doc false
  def changeset(game, attrs) do
    game
    |> cast(attrs, [:name, :code, :url])
    |> ValidationHelper.allow_empty_strings()
    |> validate_required([:name, :code])
  end
end
