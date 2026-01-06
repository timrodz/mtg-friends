defmodule MtgFriends.Repo.Migrations.RefactorPairingsComplete do
  use Ecto.Migration

  def up do
    # 1. Rename existing table
    rename table(:pairings), to: table(:pairing_participants)

    # 1.1 Rename indexes to avoid conflict with new table indexes
    execute "ALTER INDEX IF EXISTS pairings_pkey RENAME TO pairing_participants_pkey"

    execute "ALTER INDEX IF EXISTS pairings_round_id_index RENAME TO pairing_participants_round_id_index"

    execute "ALTER INDEX IF EXISTS pairings_tournament_id_index RENAME TO pairing_participants_tournament_id_index"

    execute "ALTER INDEX IF EXISTS pairings_participant_id_index RENAME TO pairing_participants_participant_id_index"

    # 2. Create new pairings table
    create table(:pairings) do
      # number is temporarily needed for backfill but will be dropped
      add :number, :integer
      add :active, :boolean, default: true, null: false
      add :round_id, references(:rounds, on_delete: :delete_all)
      add :tournament_id, references(:tournaments, on_delete: :delete_all)

      timestamps()
    end

    create index(:pairings, [:round_id])
    create index(:pairings, [:tournament_id])
    create unique_index(:pairings, [:round_id, :number])

    # 3. Add foreign key to pairing_participants
    alter table(:pairing_participants) do
      add :pairing_id, references(:pairings, on_delete: :delete_all)
    end

    create index(:pairing_participants, [:pairing_id])

    # 4. DATA BACKFILL
    # Create pairings based on distinct (round_id, number) groups
    execute """
    INSERT INTO pairings (number, active, round_id, tournament_id, inserted_at, updated_at)
    SELECT number, bool_or(active), round_id, min(tournament_id), min(inserted_at), min(updated_at)
    FROM pairing_participants
    GROUP BY number, round_id
    """

    # Link participants to new pairings
    execute """
    UPDATE pairing_participants pp
    SET pairing_id = p.id
    FROM pairings p
    WHERE pp.round_id = p.round_id AND pp.number = p.number
    """

    # 5. Add winner_id to pairings (referencing pairing_participants)
    alter table(:pairings) do
      add :winner_id, references(:pairing_participants, on_delete: :nilify_all)
    end

    create index(:pairings, [:winner_id])

    # 6. Backfill winner
    execute """
    UPDATE pairings p
    SET winner_id = pp.id
    FROM pairing_participants pp
    WHERE pp.pairing_id = p.id AND pp.winner = true
    """

    # 7. Cleanup pairing_participants
    alter table(:pairing_participants) do
      remove :number
      remove :active
      remove :round_id
      remove :tournament_id
      remove :winner
    end

    # 8. Cleanup pairings (User requested removal of number)
    drop unique_index(:pairings, [:round_id, :number])

    alter table(:pairings) do
      remove :number
    end
  end

  def down do
    # 1. Add back columns to pairings
    alter table(:pairings) do
      add :number, :integer
    end

    create unique_index(:pairings, [:round_id, :number])

    # 2. Add back columns to pairing_participants
    alter table(:pairing_participants) do
      add :number, :integer
      add :active, :boolean, default: true
      add :round_id, references(:rounds, on_delete: :delete_all)
      add :tournament_id, references(:tournaments, on_delete: :delete_all)
      add :winner, :boolean, default: false
    end

    # 3. Restore data
    # Restore winner
    execute """
    UPDATE pairing_participants pp
    SET winner = true
    FROM pairings p
    WHERE p.winner_id = pp.id
    """

    # Restore other fields - NOTE: 'number' on pairings may be lost if not inferred,
    # but we can try to restore it via row_number or just rely on the fact that existing data had it.
    # HOWEVER, we dropped 'number' in up. If we can't recover it, we can't fully rollback pairing.number
    # unless we store it somewhere or just infer it.
    # We will attempt to restore simple fields.
    execute """
    UPDATE pairing_participants pp
    SET
      active = p.active,
      round_id = p.round_id,
      tournament_id = p.tournament_id
    FROM pairings p
    WHERE pp.pairing_id = p.id
    """

    # We cannot easily restore 'number' exactly if we dropped it, unless we re-calculate it.
    # Accepting data loss for rollback of 'number' if user insists on deleting it in forward migration.

    # 4. Drop relationships
    alter table(:pairings) do
      remove :winner_id
    end

    drop index(:pairing_participants, [:pairing_id])

    alter table(:pairing_participants) do
      remove :pairing_id
    end

    # 5. Drop new table and indexes
    drop table(:pairings)

    # 6. Rename indexes back
    execute "ALTER INDEX IF EXISTS pairing_participants_round_id_index RENAME TO pairings_round_id_index"

    execute "ALTER INDEX IF EXISTS pairing_participants_tournament_id_index RENAME TO pairings_tournament_id_index"

    execute "ALTER INDEX IF EXISTS pairing_participants_participant_id_index RENAME TO pairings_participant_id_index"

    execute "ALTER INDEX IF EXISTS pairing_participants_pkey RENAME TO pairings_pkey"

    # 7. Rename back
    rename table(:pairing_participants), to: table(:pairings)
  end
end
