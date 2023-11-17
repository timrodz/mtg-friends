defmodule MtgFriends.Pairings do
  @moduledoc """
  The Pairings context.
  """

  import Ecto.Query, warn: false
  alias MtgFriends.Participants
  alias MtgFriends.Pairings
  alias MtgFriends.Repo

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

  # TODO:
  # def create_pairings(tournament_id, round_id, participant_pairings) do
  #   pairing_info =
  #     participant_pairings
  #     |> Enum.with_index(fn pairing, index ->
  #       for participant <- pairing do
  #         Pairings.create_pairing(%{
  #           number: index,
  #           tournament_id: tournament_id,
  #           round_id: round_id,
  #           participant_id: participant.id
  #         })
  #       end
  #     end)

  #   multi =
  #     Enum.reduce(participant_pairings, Ecto.Multi.new(), fn {pairing, index}, multi ->
  #       pairing |> Enum.map()

  #       pairing_changeset =
  #         %Pairing{} |> Pairing.changeset(%{tournament_id: tournament_id, round_id: round_id})

  #       Ecto.Multi.insert(
  #         multi,
  #         "update_tournament_#{tournament_id}_round_#{round_id}",
  #         pairing_changeset
  #       )
  #     end)

  #   MtgFriends.Repo.transaction(multi)
  # end

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

  def update_pairings(tournament_id, round_id, winner_id, form_params) do
    form_params |> IO.inspect(label: "form_params")

    participant_scores =
      Enum.map(Map.drop(form_params, ["pairing-number", "winner_id"]), fn {participant_id_str,
                                                                           score_str} ->
        participant_id =
          String.replace_prefix(participant_id_str, "input-points-participant-", "")

        {points, ""} = Integer.parse(score_str)

        %{
          "id" => participant_id,
          "points" => points,
          "winner" => winner_id == participant_id,
          "active" => false
        }
      end)
      |> IO.inspect(label: "participant_scores")

    multi =
      Enum.reduce(participant_scores, Ecto.Multi.new(), fn %{"id" => participant_id} =
                                                             params,
                                                           multi ->
        with pairing <- Pairings.get_pairing!(tournament_id, round_id, participant_id) do
          pairing_changeset =
            Pairings.change_pairing(pairing, params)
            |> IO.inspect(
              label: "pairing #{pairing.id} / participant #{participant_id} changeset"
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
