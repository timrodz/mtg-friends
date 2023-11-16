defmodule MtgFriends.Participants.Participant do
  use Ecto.Schema
  import Ecto.Changeset
  import ValidationHelper

  schema "participants" do
    field :name, :string
    field :points, :integer
    field :decklist, :string

    belongs_to :tournament, MtgFriends.Tournaments.Tournament
    timestamps()
  end

  @doc false
  def changeset(participant, attrs) do
    participant
    |> cast(attrs, [:name, :points, :decklist])
    |> allow_empty_strings()

    # |> validate_required([:name, :points, :decklist])
  end
end
