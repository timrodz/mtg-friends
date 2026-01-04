defmodule MtgFriends.Participants.Participant do
  use Ecto.Schema
  import Ecto.Changeset

  schema "participants" do
    field :name, :string, default: ""
    field :points, :integer, default: 0
    field :decklist, :string, default: ""
    field :is_tournament_winner, :boolean, default: false
    field :is_dropped, :boolean, default: false
    field :win_rate, :float, default: 0.0

    belongs_to :tournament, MtgFriends.Tournaments.Tournament
    has_many :pairing_participants, MtgFriends.Pairings.PairingParticipant

    timestamps()
  end

  @doc false
  def changeset(participant, attrs) do
    participant
    |> cast(attrs, [
      :name,
      :points,
      :decklist,
      :tournament_id,
      :is_tournament_winner,
      :is_dropped,
      :win_rate
    ])
    |> validate_required([:tournament_id])
    |> validate_length(:name, min: 1)
  end
end
