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

  @type t :: %__MODULE__{
          id: integer() | nil,
          active: boolean() | nil,
          tournament_id: integer() | nil,
          tournament:
            MtgFriends.Tournaments.Tournament.t() | Ecto.Association.NotLoaded.t() | nil,
          round_id: integer() | nil,
          round: MtgFriends.Rounds.Round.t() | Ecto.Association.NotLoaded.t() | nil,
          winner_id: integer() | nil,
          winner: MtgFriends.Participants.Participant.t() | nil | Ecto.Association.NotLoaded.t(),
          pairing_participants:
            [MtgFriends.Pairings.PairingParticipant.t()]
            | Ecto.Association.NotLoaded.t(),
          participants:
            [MtgFriends.Participants.Participant.t()] | Ecto.Association.NotLoaded.t(),
          inserted_at: NaiveDateTime.t() | nil,
          updated_at: NaiveDateTime.t() | nil
        }

  @doc false
  def changeset(pairing, attrs) do
    pairing
    |> cast(attrs, [:active, :tournament_id, :round_id, :winner_id])
    |> cast_assoc(:pairing_participants)
    |> validate_required([:tournament_id, :round_id])
  end
end
