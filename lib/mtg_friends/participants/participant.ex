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

  @type t :: %__MODULE__{
          id: integer() | nil,
          name: String.t() | nil,
          points: integer() | nil,
          decklist: String.t() | nil,
          is_tournament_winner: boolean() | nil,
          is_dropped: boolean() | nil,
          win_rate: float() | nil,
          tournament_id: integer() | nil,
          tournament:
            MtgFriends.Tournaments.Tournament.t() | Ecto.Association.NotLoaded.t() | nil,
          pairing_participants:
            [MtgFriends.Pairings.PairingParticipant.t()]
            | Ecto.Association.NotLoaded.t(),
          inserted_at: NaiveDateTime.t() | nil,
          updated_at: NaiveDateTime.t() | nil
        }

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
  end
end
