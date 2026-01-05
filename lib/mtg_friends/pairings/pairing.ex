defmodule MtgFriends.Pairings.Pairing do
  use Ecto.Schema
  import Ecto.Changeset

  schema "pairings" do
    field :active, :boolean

    belongs_to :tournament, MtgFriends.Tournaments.Tournament
    belongs_to :round, MtgFriends.Rounds.Round
    belongs_to :winner, MtgFriends.Participants.Participant

    has_many :pairing_participants, MtgFriends.Pairings.PairingParticipant, on_replace: :delete
    has_many :participants, through: [:pairing_participants, :participant]

    timestamps()
  end

  @doc false
  def changeset(pairing, attrs) do
    pairing
    |> cast(attrs, [:active, :tournament_id, :round_id, :winner_id])
    |> cast_assoc(:pairing_participants)
    |> validate_required([:tournament_id, :round_id])
  end
end
