defmodule MtgFriends.Rounds.Round do
  use Ecto.Schema
  import Ecto.Changeset

  schema "rounds" do
    field :active, :boolean
    field :number, :integer

    belongs_to :tournament, MtgFriends.Tournaments.Tournament

    has_many :pairings, MtgFriends.Pairings.Pairing

    timestamps()
  end

  @doc false
  def changeset(round, attrs) do
    round
    |> cast(attrs, [:active, :number, :tournament_id])
    |> validate_required([:active, :number, :tournament_id])
  end
end
