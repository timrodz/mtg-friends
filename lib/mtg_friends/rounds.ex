defmodule MtgFriends.Rounds do
  @moduledoc """
  The Rounds context.
  """

  import Ecto.Query, warn: false
  alias MtgFriends.Repo

  alias MtgFriends.Rounds.Round

  @doc """
  Returns the list of rounds.

  ## Examples

      iex> list_rounds()
      [%Round{}, ...]

  """
  def list_rounds do
    Repo.all(Round)
  end

  @doc """
  Gets a single round.

  Raises `Ecto.NoResultsError` if the Round does not exist.

  ## Examples

      iex> get_round!(123)
      %Round{}

      iex> get_round!(456)
      ** (Ecto.NoResultsError)

  """
  def get_round!(id, preload_all \\ false) do
    if preload_all do
      Repo.get!(Round, id) |> Repo.preload(tournament: [:participants], pairings: [:participant])
    else
      Repo.get!(Round, id)
    end
  end

  def get_round_by_tournament_and_round_number!(tournament_id, round_number, preload_all \\ false) do
    if preload_all do
      Repo.get_by!(Round, tournament_id: tournament_id, number: round_number)
      |> Repo.preload(tournament: [:participants, rounds: [:pairings]], pairings: [:participant])
    else
      Repo.get_by!(Round, tournament_id: tournament_id, number: round_number)
      |> Repo.preload(pairings: [:participant])
    end
  end

  def get_round_from_round_number_str!(tournament_id, number_str) do
    {number, ""} = Integer.parse(number_str)

    Repo.get_by!(Round, tournament_id: tournament_id, number: number - 1)
    |> Repo.preload(tournament: [:participants, rounds: :pairings], pairings: [:participant])
  end

  @doc """
  Creates a round.

  ## Examples

      iex> create_round(%{field: value})
      {:ok, %Round{}}

      iex> create_round(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_round(tournament_id, tournament_rounds) do
    %Round{}
    |> Round.changeset(%{
      tournament_id: tournament_id,
      number: tournament_rounds
    })
    |> Repo.insert()
  end

  @doc """
  Updates a round.

  ## Examples

      iex> update_round(round, %{field: new_value})
      {:ok, %Round{}}

      iex> update_round(round, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_round(%Round{} = round, attrs) do
    round
    |> Round.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a round.

  ## Examples

      iex> delete_round(round)
      {:ok, %Round{}}

      iex> delete_round(round)
      {:error, %Ecto.Changeset{}}

  """
  def delete_round(%Round{} = round) do
    Repo.delete(round)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking round changes.

  ## Examples

      iex> change_round(round)
      %Ecto.Changeset{data: %Round{}}

  """
  def change_round(%Round{} = round, attrs \\ %{}) do
    Round.changeset(round, attrs)
  end
end
