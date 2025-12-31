defmodule MtgFriends.Pairings.PairingParticipant do
  use Ecto.Schema
  import Ecto.Changeset

  schema "pairing_participants" do
    field :points, :integer

    belongs_to :pairing, MtgFriends.Pairings.Pairing
    belongs_to :participant, MtgFriends.Participants.Participant

    timestamps()
  end

  @doc false
  def changeset(pairing_participant, attrs) do
    pairing_participant
    |> cast(attrs, [:points, :pairing_id, :participant_id])
    |> validate_required([:participant_id])
  end
end
