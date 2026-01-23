defmodule MtgFriends.Rounds.Round do
  use Ecto.Schema
  import Ecto.Changeset

  schema "rounds" do
    field :status, Ecto.Enum, values: [:inactive, :active, :finished], default: :inactive
    field :number, :integer
    field :started_at, :naive_datetime

    belongs_to :tournament, MtgFriends.Tournaments.Tournament

    has_many :pairings, MtgFriends.Pairings.Pairing

    timestamps()
  end

  @type t :: %__MODULE__{
          id: integer() | nil,
          status: :inactive | :active | :finished | nil,
          number: integer() | nil,
          started_at: NaiveDateTime.t() | nil,
          tournament_id: integer() | nil,
          tournament:
            MtgFriends.Tournaments.Tournament.t() | Ecto.Association.NotLoaded.t() | nil,
          pairings: [MtgFriends.Pairings.Pairing.t()] | Ecto.Association.NotLoaded.t(),
          inserted_at: NaiveDateTime.t() | nil,
          updated_at: NaiveDateTime.t() | nil
        }

  @doc false
  def changeset(round, attrs) do
    round
    |> cast(attrs, [:status, :number, :tournament_id, :started_at])
    |> validate_required([:status, :number, :tournament_id])
  end
end
