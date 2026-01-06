defmodule MtgFriends.Rounds do
  @moduledoc """
  The Rounds context.
  """

  import Ecto.Query, warn: false
  alias MtgFriends.Repo

  alias MtgFriends.Participants.Participant
  alias MtgFriends.Tournaments.Tournament
  alias MtgFriends.{Participants, Tournaments}
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

  def list_rounds(tournament_id) do
    Repo.all(from r in Round, where: r.tournament_id == ^tournament_id, order_by: [asc: r.number])
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
      Repo.get!(Round, id)
      |> Repo.preload(tournament: [:participants], pairings: [pairing_participants: :participant])
    else
      Repo.get!(Round, id)
    end
  end

  def get_round_by_tournament_and_round_id!(tournament_id, id, preload_all \\ false) do
    if preload_all do
      Repo.get_by!(Round, tournament_id: tournament_id, id: id)
      |> Repo.preload(
        tournament: [:participants, rounds: [:pairings]],
        pairings: [pairing_participants: :participant]
      )
    else
      Repo.get_by!(Round, tournament_id: tournament_id, id: id)
      |> Repo.preload(pairings: [pairing_participants: :participant])
    end
  end

  def get_round_by_tournament_and_round_number!(tournament_id, round_number, preload_all \\ false) do
    if preload_all do
      Repo.get_by!(Round, tournament_id: tournament_id, number: round_number)
      |> Repo.preload(
        tournament: [:participants, rounds: [:pairings]],
        pairings: [pairing_participants: :participant]
      )
    else
      Repo.get_by!(Round, tournament_id: tournament_id, number: round_number)
      |> Repo.preload(pairings: [pairing_participants: :participant])
    end
  end

  def get_round_from_round_number_str!(tournament_id, number_str) do
    {number, ""} = Integer.parse(number_str)

    Repo.get_by!(Round, tournament_id: tournament_id, number: number - 1)
    |> Repo.preload(
      tournament: [:participants, rounds: :pairings],
      pairings: [pairing_participants: :participant]
    )
  end

  @doc """
  Creates a round.

  ## Examples

      iex> create_round(%{field: value})
      {:ok, %Round{}}

      iex> create_round(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_round(attrs \\ %{}) do
    %Round{}
    |> Round.changeset(attrs)
    |> Repo.insert()
  end

  def start_round(tournament) do
    # Preload necessary associations if not already loaded
    tournament = Repo.preload(tournament, [:participants, :rounds])

    with true <- Tournaments.has_enough_participants?(tournament),
         true <- Tournaments.all_participants_named?(tournament),
         false <- is_any_round_active?(tournament.rounds) do
      Repo.transaction(fn ->
        round_number = length(tournament.rounds)

        # 1. Create Round
        {:ok, round} =
          %Round{}
          |> Round.changeset(%{
            tournament_id: tournament.id,
            number: round_number,
            status: :active,
            started_at: NaiveDateTime.utc_now()
          })
          |> Repo.insert()

        # 2. Create Pairings
        # We need to use Pairings context, so we'll add alias MtgFriends.Pairings to the module top if needed,
        # or use fully qualified name. Let's use fully qualified name or ensure alias.
        # Checking existing aliases... we have alias MtgFriends.{Participants, Tournaments}
        # Let's use MtgFriends.Pairings.create_pairings_for_round

        {:ok, _pairings} = MtgFriends.Pairings.create_pairings_for_round(tournament, round)

        # 3. Update Tournament if first round
        if round_number == 0 do
          Tournaments.update_tournament(tournament, %{"status" => :active})
        end

        round
      end)
    else
      false ->
        {:error, "Conditions not met to start a round"}

      # We should return specific errors ideally
      _ ->
        {:error, "Cannot start round: Ensure 4+ participants, all named, and no active rounds."}
    end
  end

  defp is_any_round_active?(rounds) do
    Enum.any?(rounds, fn r -> r.status == :active end)
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

  def is_round_complete?(%Round{} = round) do
    round.status == :finished
  end

  def check_and_finalize(round, tournament) do
    # Force reload pairings to ensure we have latest state
    round = Repo.preload(round, [:pairings], force: true)

    # Check if all pairings are inactive
    if Enum.all?(round.pairings, fn p -> p.active == false end) do
      transaction_result =
        Repo.transaction(fn ->
          case update_round(round, %{status: :finished}) do
            {:ok, round} ->
              # Update scores for all participants
              MtgFriends.Participants.calculate_and_update_scores(tournament.id)

              is_last_round? = tournament.round_count == round.number + 1

              if is_last_round? do
                {:ok, %Tournament{}} = finalize_tournament(tournament, round.pairings)
                {:ok, round, :tournament_finished}
              else
                {:ok, round, :round_finished}
              end

            {:error, changeset} ->
              Repo.rollback(changeset)
          end
        end)

      case transaction_result do
        {:ok, result} -> result
        {:error, reason} -> {:error, reason}
      end
    else
      # Not complete yet
      {:ok, round, :active}
    end
  end

  defp finalize_tournament(tournament, pairings) do
    winning_participant = get_winning_participant(tournament, pairings)

    with false <- is_nil(winning_participant) do
      {:ok, %Participant{}} =
        Participants.update_participant(winning_participant, %{
          "is_tournament_winner" => true
        })
    end

    Tournaments.update_tournament(tournament, %{"status" => :finished})
  end

  defp get_winning_participant(tournament, pairings)
       when length(pairings) == 1 and tournament.is_top_cut_4 do
    pairing = Repo.preload(pairings, winner: :participant) |> hd()

    pairing.winner.participant
  end

  defp get_winning_participant(tournament, _pairings) do
    tournament =
      if Ecto.assoc_loaded?(tournament.participants),
        do: tournament.participants,
        else: Repo.preload(tournament, :participants)

    tournament.participants
    |> Enum.max_by(&{&1.points, &1.win_rate})
  end
end
