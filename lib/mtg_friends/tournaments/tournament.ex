defmodule MtgFriends.Tournaments.Tournament do
  use Ecto.Schema
  import Ecto.Changeset

  alias ValidationHelper
  alias MtgFriends.Utils.ProfanityFilter

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
    field :subformat, Ecto.Enum, values: [:bubble_rounds, :swiss, :round_robin], default: :bubble_rounds

    belongs_to :user, MtgFriends.Accounts.User
    belongs_to :game, MtgFriends.Games.Game

    has_many :participants, MtgFriends.Participants.Participant
    has_many :rounds, MtgFriends.Rounds.Round

    timestamps()
  end

  @type t :: %__MODULE__{
          id: integer() | nil,
          name: String.t() | nil,
          location: String.t() | nil,
          date: NaiveDateTime.t() | nil,
          description_raw: String.t() | nil,
          description_html: String.t() | nil,
          round_length_minutes: integer() | nil,
          is_top_cut_4: boolean() | nil,
          round_count: integer() | nil,
          status: :inactive | :active | :finished | nil,
          format: :edh | :standard | nil,
          subformat: :bubble_rounds | :swiss | :round_robin | nil,
          user_id: integer() | nil,
          user: MtgFriends.Accounts.User.t() | Ecto.Association.NotLoaded.t() | nil,
          game_id: integer() | nil,
          game: MtgFriends.Games.Game.t() | Ecto.Association.NotLoaded.t() | nil,
          participants:
            [MtgFriends.Participants.Participant.t()] | Ecto.Association.NotLoaded.t(),
          rounds: [MtgFriends.Rounds.Round.t()] | Ecto.Association.NotLoaded.t(),
          inserted_at: NaiveDateTime.t() | nil,
          updated_at: NaiveDateTime.t() | nil
        }

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
    |> validate_length(:name, min: 4)
    |> validate_length(:location, min: 4)
    |> validate_required([
      :user_id,
      :game_id,
      :name,
      :location,
      :date
    ])
    |> validate_name()
  end

  defp validate_name(changeset) do
    validate_change(changeset, :name, fn :name, name ->
      if ProfanityFilter.is_text_profane?(name) do
        [name: "contains restricted words"]
      else
        []
      end
    end)
  end
end
