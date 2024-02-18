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

  @doc false
  def changeset(round, attrs) do
    round
    |> cast(attrs, [:status, :number, :tournament_id, :started_at])
    |> validate_required([:status, :number, :tournament_id])
  end
end
