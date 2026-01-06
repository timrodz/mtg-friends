defmodule MtgFriends.Repo.Migrations.ChangeWinnerIdToParticipantId do
  use Ecto.Migration

  def up do
    # Drop existing constraint
    execute "ALTER TABLE pairings DROP CONSTRAINT IF EXISTS pairings_winner_id_fkey"

    # Update existing data: winner_id currently points to pairing_participants.id
    # We want it to point to pairing_participants.participant_id
    execute """
    UPDATE pairings
    SET winner_id = pp.participant_id
    FROM pairing_participants pp
    WHERE pairings.winner_id = pp.id
    """

    # Add new constraint referencing participants
    alter table(:pairings) do
      modify :winner_id, references(:participants, on_delete: :nilify_all)
    end
  end

  def down do
    execute "ALTER TABLE pairings DROP CONSTRAINT IF EXISTS pairings_winner_id_fkey"

    # Revert data: participant_id -> pairing_participant_id
    execute """
    UPDATE pairings
    SET winner_id = pp.id
    FROM pairing_participants pp
    WHERE pairings.winner_id = pp.participant_id AND pp.pairing_id = pairings.id
    """

    alter table(:pairings) do
      modify :winner_id, references(:pairing_participants, on_delete: :nilify_all)
    end
  end
end
