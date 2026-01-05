defmodule MtgFriends.Participants do
  @moduledoc """
  The Participants context.
  """

  import Ecto.Query, warn: false
  alias MtgFriends.Repo

  alias MtgFriends.Participants.Participant

  @doc """
  Returns the list of participants.

  ## Examples

      iex> list_participants()
      [%Participant{}, ...]

  """
  def list_participants do
    Repo.all(Participant)
  end

  @doc """
  Returns the list of participants for a tournament

  ## Examples

      iex> list_participants_by_tournament(1)
      [%Participant{}, ...]

  """
  def list_participants_by_tournament(tournament_id) do
    Repo.all(from p in Participant, where: p.tournament_id == ^tournament_id)
  end

  @doc """
  Gets a single participant.

  Raises `Ecto.NoResultsError` if the Participant does not exist.

  ## Examples

      iex> get_participant!(123)
      %Participant{}

      iex> get_participant!(456)
      ** (Ecto.NoResultsError)

  """
  def get_participant!(id), do: Repo.get!(Participant, id)

  @doc """
  Creates a participant.

  ## Examples

      iex> create_participant(%{field: value})
      {:ok, %Participant{}}

      iex> create_participant(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_participant(attrs \\ %{}) do
    %Participant{}
    |> Participant.changeset(attrs)
    |> Repo.insert()
  end

  def create_empty_participant(tournament_id) do
    now = NaiveDateTime.local_now()

    create_participant(%{
      inserted_at: now,
      updated_at: now,
      name: "",
      points: 0,
      decklist: "",
      tournament_id: tournament_id
    })
  end

  def create_x_participants(tournament_id, participants) do
    now = NaiveDateTime.local_now()

    multi =
      participants
      |> Enum.with_index()
      |> Enum.reduce(Ecto.Multi.new(), fn {participant, index}, multi ->
        changeset =
          %Participant{}
          |> Participant.changeset(%{
            inserted_at: now,
            updated_at: now,
            name: participant |> String.trim() |> String.capitalize(),
            points: 0,
            decklist: "",
            tournament_id: tournament_id
          })

        Ecto.Multi.insert(
          multi,
          "update_tournament_#{tournament_id}_create_participant_#{index}",
          changeset
        )
      end)

    MtgFriends.Repo.transaction(multi)
  end

  @doc """
  Updates a participant.

  ## Examples

      iex> update_participant(participant, %{field: new_value})
      {:ok, %Participant{}}

      iex> update_participant(participant, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_participant(%Participant{} = participant, attrs) do
    participant
    |> Participant.changeset(attrs)
    |> Repo.update()
  end

  defp changeset_from_string_form(name, decklist) do
    name_valid = not is_nil(name) and name != ""
    decklist_valid = not is_nil(decklist) and name != ""

    if name_valid and decklist_valid do
      %{"name" => name |> String.capitalize(), "decklist" => decklist}
    else
      if name_valid do
        %{"name" => name |> String.capitalize(), "decklist" => decklist}
      else
        %{"decklist" => decklist}
      end
    end
  end

  def update_participants_for_tournament(tournament_id, participants, form_changes) do
    multi =
      Enum.reduce(participants, Ecto.Multi.new(), fn participant, multi ->
        with id <- participant.id,
             name <- form_changes["form-participant-name-#{id}"],
             decklist <- form_changes["form-participant-decklist-#{id}"],
             participant <- get_participant!(id) do
          changeset = change_participant(participant, changeset_from_string_form(name, decklist))

          Ecto.Multi.update(
            multi,
            "update_tournament_#{tournament_id}_participant_#{id}",
            changeset
          )
        end
      end)

    if multi do
      MtgFriends.Repo.transaction(multi)
    else
      {:error, :no_changes_detected}
    end
  end

  @doc """
  Deletes a participant.

  ## Examples

      iex> delete_participant(participant)
      {:ok, %Participant{}}

      iex> delete_participant(participant)
      {:error, %Ecto.Changeset{}}

  """
  def delete_participant(%Participant{} = participant) do
    Repo.delete(participant)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking participant changes.

  ## Examples

      iex> change_participant(participant)
      %Ecto.Changeset{data: %Participant{}}

  """
  def change_participant(%Participant{} = participant, attrs \\ %{}) do
    Participant.changeset(participant, attrs)
  end

  def calculate_and_update_scores(tournament_id) do
    # 1. Fetch all participants for the tournament
    participants = list_participants_by_tournament(tournament_id)

    # 2. Inspect round count to determine denominator (or use match count)
    # The previous logic used `round_count` from the list of rounds.
    # To be consistent with "Win Rate", using matches played is safer for dropped players,
    # OR using tournament round count if that's the intention.
    # Let's use matches played (count of pairings) as the denominator for match win rate.

    Repo.transaction(fn ->
      Enum.each(participants, fn participant ->
        stats =
          MtgFriends.Repo.one(
            from pp in MtgFriends.Pairings.PairingParticipant,
              join: p in MtgFriends.Pairings.Pairing,
              on: p.id == pp.pairing_id,
              join: r in MtgFriends.Rounds.Round,
              on: r.id == p.round_id,
              where: pp.participant_id == ^participant.id and r.tournament_id == ^tournament_id,
              select: %{
                total_points: sum(pp.points),
                match_count: count(pp.id),
                wins: filter(count(pp.id), p.winner_id == pp.id)
              }
          )

        total_points = stats.total_points || 0
        match_count = stats.match_count || 0
        wins = stats.wins || 0

        # Avoid division by zero
        win_rate =
          if match_count > 0 do
            wins / match_count * 100
          else
            0.0
          end

        update_participant(participant, %{points: total_points, win_rate: win_rate})
      end)
    end)
  end

  @doc """
  Calculates overall standings for all participants based on stored points and win rate.

  Returns a list of participant score maps sorted by total score and win rate.
  """
  def get_participant_standings(participants) do
    participants
    |> Enum.map(fn participant ->
      %{
        id: participant.id,
        total_score: participant.points || 0,
        win_rate: Decimal.from_float(participant.win_rate || 0.0)
      }
    end)
    # Sort by total score (desc) and then win rate (desc)
    |> Enum.sort_by(&{&1.total_score, &1.win_rate}, :desc)
  end
end
