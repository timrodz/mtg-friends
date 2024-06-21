defmodule MtgFriends.Tournaments.Tournament do
  use Ecto.Schema
  import Ecto.Changeset

  alias ValidationHelper

  schema "tournaments" do
    field :name, :string
    field :location, :string
    field :date, :naive_datetime
    field :description_raw, :string
    field :description_html, :string
    field :round_length_minutes, :integer, default: 60
    field :is_top_cut_4, :boolean, default: false
    field :round_count, :integer, default: 4
    field :status, Ecto.Enum, values: [:inactive, :active, :finished], default: :inactive
    field :format, Ecto.Enum, values: [:edh, :standard], default: :edh
    field :subformat, Ecto.Enum, values: [:bubble_rounds, :swiss], default: :swiss

    belongs_to :user, MtgFriends.Accounts.User
    belongs_to :game, MtgFriends.Games.Game

    has_many :participants, MtgFriends.Participants.Participant
    has_many :rounds, MtgFriends.Rounds.Round

    timestamps()
  end

  @doc false
  def changeset(tournament, attrs) do
    tournament
    |> cast(attrs, [
      :user_id,
      :game_id,
      :name,
      :location,
      :date,
      :description_raw,
      :description_html,
      :round_length_minutes,
      :round_count,
      :status,
      :format,
      :subformat,
      :is_top_cut_4
    ])
    |> validate_length(:name, min: 5)
    |> validate_length(:location, min: 5)
    |> validate_length(:description_raw, min: 20)
    |> validate_required([
      :user_id,
      :game_id,
      :name,
      :location,
      :date,
      :description_raw
    ])
  end
end
