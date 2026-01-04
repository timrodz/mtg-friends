defmodule MtgFriends.Pairings do
  @moduledoc """
  The Pairings context.
  """

  import Ecto.Query, warn: false
  alias MtgFriends.Repo

  alias MtgFriends.Pairings.Pairing
  alias MtgFriends.Pairings.PairingParticipant

  @doc """
  Returns the list of pairings.
  """
  def list_pairings do
    Repo.all(Pairing)
    |> Repo.preload(:pairing_participants)
  end

  def list_pairings(tournament_id, round_id) do
    Repo.all(
      from p in Pairing,
        where: p.tournament_id == ^tournament_id and p.round_id == ^round_id,
        preload: [:pairing_participants]
    )
  end

  @doc """
  Gets a single pairing.
  """
  def get_pairing!(id), do: Repo.get!(Pairing, id) |> Repo.preload(:pairing_participants)

  def get_pairing(id) do
    case Repo.get(Pairing, id) do
      nil -> {:error, :not_found}
      pairing -> {:ok, Repo.preload(pairing, :pairing_participants)}
    end
  end

  def get_pairing_participant!(pairing_id, participant_id),
    do:
      Repo.get_by!(PairingParticipant,
        pairing_id: pairing_id,
        participant_id: participant_id
      )

  @doc """
  Creates a pairing.
  """
  def create_pairing(attrs \\ %{}) do
    %Pairing{}
    |> Pairing.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Creates multiple pairings with nested participants.
  Expects a list of maps where each map represents a Pairing and has a `pairing_participants` key.
  """
  def create_multiple_pairings(pairings_data) do
    # Since insert_all doesn't support nested associations easily with IDs returned,
    # and we have a hierarchical structure now, we might need to use Ecto.Multi or Enum.each.
    # Given the scale of a tournament (tens of pairings), doing sequential inserts in a transaction is fine.

    Ecto.Multi.new()
    |> Ecto.Multi.run(:insert_pairings, fn repo, _ ->
      results =
        Enum.map(pairings_data, fn pairing_attrs ->
          %Pairing{}
          |> Pairing.changeset(pairing_attrs)
          |> Ecto.Changeset.put_assoc(:pairing_participants, pairing_attrs.pairing_participants)
          |> repo.insert()
        end)

      # If any failed, return error. Otherwise return list of successful pairings.
      failed = Enum.find(results, fn {status, _} -> status == :error end)

      if failed do
        failed
      else
        {:ok, Enum.map(results, fn {:ok, p} -> p end)}
      end
    end)
    |> Repo.transaction()
  end

  @doc """
  Updates a pairing.
  """
  def update_pairing(%Pairing{} = pairing, attrs) do
    pairing
    |> Pairing.changeset(attrs)
    |> Repo.update()
  end

  def update_pairings(tournament_id, round_id, form_params) do
    # form_params contains keys like "input-points-participant-<ID>" => "score"
    # We need to group these by Pairing (since we determine winner per pairing).
    # But filtering by tournament_id/round_id isn't directly giving us pairings unless we fetch them.

    pairings = list_pairings(tournament_id, round_id)

    multi = Ecto.Multi.new()

    multi =
      Enum.reduce(pairings, multi, fn pairing, acc_multi ->
        # Filter params relevant to this pairing's participants
        participants_in_pairing = Enum.map(pairing.pairing_participants, & &1.participant_id)

        relevant_scores =
          Enum.map(participants_in_pairing, fn pid ->
            score_str = form_params["input-points-participant-#{pid}"]

            if score_str do
              {points, ""} = Integer.parse(score_str)
              {pid, points}
            else
              nil
            end
          end)
          |> Enum.reject(&is_nil/1)

        if Enum.empty?(relevant_scores) do
          acc_multi
        else
          # Determine winner for this pairing
          {winner_pid, _} =
            highest = Enum.max_by(relevant_scores, fn {_, points} -> points end)

          # Handle draws - check if duplicates of max score exist
          max_points = elem(highest, 1)
          draw = Enum.count(relevant_scores, fn {_, p} -> p == max_points end) > 1

          winner_id = if draw, do: nil, else: winner_pid

          # 1. Update Pairing (winner_id)
          # We need the PairingParticipant ID for the winner_id
          winner_pp_id =
            if winner_id do
              Enum.find(pairing.pairing_participants, fn pp -> pp.participant_id == winner_id end).id
            else
              nil
            end

          acc_multi =
            Ecto.Multi.update(
              acc_multi,
              "update_pairing_#{pairing.id}",
              Pairing.changeset(pairing, %{winner_id: winner_pp_id, active: false})
            )

          # 2. Update PairingParticipants (points)
          Enum.reduce(relevant_scores, acc_multi, fn {pid, points}, inner_multi ->
            pp = Enum.find(pairing.pairing_participants, fn pp -> pp.participant_id == pid end)

            Ecto.Multi.update(
              inner_multi,
              "update_pp_#{pp.id}",
              PairingParticipant.changeset(pp, %{points: points})
            )
          end)
        end
      end)

    MtgFriends.Repo.transaction(multi)
  end

  @doc """
  Deletes a pairing.
  """
  def delete_pairing(%Pairing{} = pairing) do
    Repo.delete(pairing)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking pairing changes.
  """
  def change_pairing(%Pairing{} = pairing, attrs \\ %{}) do
    Pairing.changeset(pairing, attrs)
  end
end
