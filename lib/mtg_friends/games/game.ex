defmodule MtgFriends.Games.Game do
  use Ecto.Schema
  import Ecto.Changeset

  schema "games" do
    field :name, :string
    field :code, Ecto.Enum, values: [:mtg, :yugioh, :pokemon], default: :mtg
    field :url, :string

    @type t :: %__MODULE__{
            id: integer() | nil,
            name: String.t() | nil,
            code: :mtg | :yugioh | :pokemon | nil,
            url: String.t() | nil,
            inserted_at: NaiveDateTime.t() | nil,
            updated_at: NaiveDateTime.t() | nil
          }

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
