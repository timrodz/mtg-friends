defmodule MtgFriends.Pairings.Pairing do
  use Ecto.Schema
  import Ecto.Changeset

  schema "pairings" do
    field :active, :boolean
    field :number, :integer
    field :points, :integer
    field :winner, :boolean

    belongs_to :tournament, MtgFriends.Tournaments.Tournament
    belongs_to :round, MtgFriends.Rounds.Round
    belongs_to :participant, MtgFriends.Participants.Participant

    timestamps()
  end

  @doc false
  def changeset(pairing, attrs) do
    pairing
    |> cast(attrs, [
      :active,
      :number,
      :points,
      :winner,
      :tournament_id,
      :round_id,
      :participant_id
    ])
    |> validate_required([:number, :tournament_id, :round_id, :participant_id])
    |> validate_number(:number, greater_than_or_equal_to: 0)
  end
end
