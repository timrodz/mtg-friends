defmodule MtgFriends.Participants.Participant do
  use Ecto.Schema
  import Ecto.Changeset
  import ValidationHelper

  schema "participants" do
    field :name, :string
    field :points, :integer
    field :decklist, :string
    field :is_tournament_winner, :boolean
    field :is_dropped, :boolean

    belongs_to :tournament, MtgFriends.Tournaments.Tournament

    timestamps()
  end

  @doc false
  def changeset(participant, attrs) do
    participant
    |> cast(attrs, [:name, :points, :decklist, :tournament_id, :is_tournament_winner, :is_dropped])
    |> IO.inspect(label: "participant changeset")
    |> allow_empty_strings()
    |> validate_required([:tournament_id])
  end
end
