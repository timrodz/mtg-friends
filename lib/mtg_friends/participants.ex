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
    |> IO.inspect(label: "create empty")
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

  def update_participants_for_tournament(tournament_id, participants, form_changes) do
    multi =
      Enum.reduce(participants, Ecto.Multi.new(), fn participant, multi ->
        with id <- participant.id,
             name <- form_changes["form-participant-name-#{id}"],
             true <- not is_nil(name) and name != "",
             decklist <- form_changes["form-participant-decklist-#{id}"],
             participant <- get_participant!(id) do
          IO.inspect(name, label: "name")

          changeset =
            change_participant(participant, %{
              "name" => name,
              "decklist" => decklist
            })
            |> IO.inspect(label: "participant #{id} changeset")

          Ecto.Multi.update(
            multi,
            "update_tournament_#{tournament_id}_participant_#{id}",
            changeset
          )
        else
          _ -> multi
        end
      end)
      |> IO.inspect(label: "multi")

    if multi do
      IO.puts("<ULTi")
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
end
