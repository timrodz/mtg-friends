defmodule MtgFriends.Rounds.Round do
  use Ecto.Schema
  import Ecto.Changeset

  schema "rounds" do
    field :active, :boolean
    field :number, :integer
    field :is_top_cut_4, :boolean

    belongs_to :tournament, MtgFriends.Tournaments.Tournament

    has_many :pairings, MtgFriends.Pairings.Pairing

    timestamps()
  end

  @doc false
  def changeset(round, attrs) do
    round
    |> cast(attrs, [:active, :number, :tournament_id, :is_top_cut_4])
    |> validate_required([:active, :number, :tournament_id])
  end
end
