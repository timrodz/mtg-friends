defmodule MtgFriends.Participants.Participant do
  use Ecto.Schema
  import Ecto.Changeset

  schema "participants" do
    field :name, :string
    field :points, :integer
    field :decklist, :string
    field :is_tournament_winner, :boolean
    field :is_dropped, :boolean

    belongs_to :tournament, MtgFriends.Tournaments.Tournament
    has_many :pairing_participants, MtgFriends.Pairings.PairingParticipant

    timestamps()
  end

  @doc false
  def changeset(participant, attrs) do
    participant
    |> cast(attrs, [:name, :points, :decklist, :tournament_id, :is_tournament_winner, :is_dropped])
    |> validate_required([:tournament_id])
    |> validate_length(:name, min: 1)
  end
end
