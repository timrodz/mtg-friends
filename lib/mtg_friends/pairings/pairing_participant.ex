defmodule MtgFriends.Pairings.PairingParticipant do
  use Ecto.Schema
  import Ecto.Changeset

  schema "pairing_participants" do
    field :points, :integer

    belongs_to :pairing, MtgFriends.Pairings.Pairing
    belongs_to :participant, MtgFriends.Participants.Participant

    timestamps()
  end

  @type t :: %__MODULE__{
          id: integer() | nil,
          points: integer() | nil,
          pairing_id: integer() | nil,
          pairing: MtgFriends.Pairings.Pairing.t() | Ecto.Association.NotLoaded.t() | nil,
          participant_id: integer() | nil,
          participant:
            MtgFriends.Participants.Participant.t() | Ecto.Association.NotLoaded.t() | nil,
          inserted_at: NaiveDateTime.t() | nil,
          updated_at: NaiveDateTime.t() | nil
        }

  @doc false
  def changeset(pairing_participant, attrs) do
    pairing_participant
    |> cast(attrs, [:points, :pairing_id, :participant_id])
    |> validate_required([:participant_id])
  end
end
