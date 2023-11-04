defmodule MtgFriends.Tournaments.Tournament do
  use Ecto.Schema
  import Ecto.Changeset
  import ValidationHelper

  schema "tournaments" do
    field :name, :string
    field :location, :string
    field :date, :date
    field :active, :boolean, default: false
    field :description, :string
    field :standings_raw, :string
    belongs_to :user, MtgFriends.Accounts.User
    # has_many :participants, MtgFriends.Participants.Participant

    timestamps()
  end

  @doc false
  def changeset(tournament, attrs) do
    IO.inspect(attrs, label: "changeset attributes")

    tournament
    |> cast(attrs, [:user_id, :name, :location, :date, :active, :description, :standings_raw])
    |> allow_empty_strings()
    |> validate_required([:user_id, :name, :location, :date, :active, :description])
  end
end
