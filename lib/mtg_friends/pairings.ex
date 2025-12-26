defmodule MtgFriends.Pairings do
  @moduledoc """
  The Pairings context.
  """

  import Ecto.Query, warn: false
  alias MtgFriends.Repo

  alias MtgFriends.Pairings
  alias MtgFriends.Pairings.Pairing

  @doc """
  Returns the list of pairings.

  ## Examples

      iex> list_pairings()
      [%Pairing{}, ...]

  """
  def list_pairings do
    Repo.all(Pairing)
  end

  @doc """
  Gets a single pairing.

  Raises `Ecto.NoResultsError` if the Pairing does not exist.

  ## Examples

      iex> get_pairing!(123)
      %Pairing{}

      iex> get_pairing!(456)
      ** (Ecto.NoResultsError)

  """
  def get_pairing!(id), do: Repo.get!(Pairing, id)

  def get_pairing(id) do
    case Repo.get(Pairing, id) do
      nil -> {:error, :not_found}
      pairing -> {:ok, pairing}
    end
  end

  def get_pairing!(tournament_id, round_id, participant_id),
    do:
      Repo.get_by(Pairing,
        tournament_id: tournament_id,
        round_id: round_id,
        participant_id: participant_id
      )
      |> Repo.preload(:participant)

  @doc """
  Creates a pairing.

  ## Examples

      iex> create_pairing(%{field: value})
      {:ok, %Pairing{}}

      iex> create_pairing(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_pairing(attrs \\ %{}) do
    %Pairing{}
    |> Pairing.changeset(attrs)
    |> Repo.insert()
  end

  def create_multiple_pairings(participant_pairings) do
    now = NaiveDateTime.local_now()

    new_pairings =
      participant_pairings
      |> Enum.map(fn p ->
        p
        |> Map.put(:inserted_at, now)
        |> Map.put(:updated_at, now)
        |> Map.put(:active, true)
      end)

    Ecto.Multi.new()
    |> Ecto.Multi.insert_all(:insert_all, Pairing, new_pairings)
    |> Repo.transaction()
  end

  @doc """
  Updates a pairing.

  ## Examples

      iex> update_pairing(pairing, %{field: new_value})
      {:ok, %Pairing{}}

      iex> update_pairing(pairing, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_pairing(%Pairing{} = pairing, attrs) do
    pairing
    |> Pairing.changeset(attrs)
    |> Repo.update()
  end

  def update_pairings(tournament_id, round_id, form_params) do
    participant_scores =
      Enum.map(Map.drop(form_params, ["pairing-number"]), fn {participant_id_str, score_str} ->
        participant_id =
          String.replace_prefix(participant_id_str, "input-points-participant-", "")

        {points, ""} = Integer.parse(score_str)

        %{
          "id" => participant_id,
          "points" => points,
          "active" => false
        }
      end)

    highest_score_pairing =
      participant_scores
      |> Enum.max_by(& &1["points"])

    # If this check passes, that means there are more than 1 pairings with the "highest scores", representing a draw
    highest_score =
      with score_groups <- participant_scores |> Enum.group_by(& &1["points"]),
           true <- length(score_groups[highest_score_pairing["points"]]) > 1 do
        nil
      else
        _ -> highest_score_pairing
      end

    multi =
      Enum.reduce(participant_scores, Ecto.Multi.new(), fn %{"id" => participant_id} =
                                                             params,
                                                           multi ->
        with pairing <- Pairings.get_pairing!(tournament_id, round_id, participant_id) do
          pairing_changeset =
            Pairings.change_pairing(
              pairing,
              Map.put(params, "winner", highest_score["id"] == participant_id)
            )

          Ecto.Multi.update(
            multi,
            "update_round_#{round_id}_pairing_#{pairing.id}_participant_#{participant_id}",
            pairing_changeset
          )
        end
      end)

    MtgFriends.Repo.transaction(multi)
  end

  @doc """
  Deletes a pairing.

  ## Examples

      iex> delete_pairing(pairing)
      {:ok, %Pairing{}}

      iex> delete_pairing(pairing)
      {:error, %Ecto.Changeset{}}

  """
  def delete_pairing(%Pairing{} = pairing) do
    Repo.delete(pairing)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking pairing changes.

  ## Examples

      iex> change_pairing(pairing)
      %Ecto.Changeset{data: %Pairing{}}

  """
  def change_pairing(%Pairing{} = pairing, attrs \\ %{}) do
    Pairing.changeset(pairing, attrs)
  end
end
