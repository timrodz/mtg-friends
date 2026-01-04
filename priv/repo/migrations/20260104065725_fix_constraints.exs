defmodule MtgFriends.Repo.Migrations.FixConstraints do
  use Ecto.Migration

  def up do
    # Pairings
    execute "DELETE FROM pairings WHERE round_id IS NULL OR tournament_id IS NULL"

    alter table(:pairings) do
      modify :round_id, :bigint, null: false
      modify :tournament_id, :bigint, null: false
    end

    # Pairing Participants
    execute "DELETE FROM pairing_participants WHERE participant_id IS NULL OR pairing_id IS NULL"

    alter table(:pairing_participants) do
      modify :participant_id, :bigint, null: false
      modify :pairing_id, :bigint, null: false
    end

    # Rounds
    execute "DELETE FROM rounds WHERE tournament_id IS NULL"
    execute "UPDATE rounds SET status = 'inactive' WHERE status IS NULL"

    alter table(:rounds) do
      modify :tournament_id, :bigint, null: false
      modify :status, :string, null: false, default: "inactive"
    end

    # Games
    execute "UPDATE games SET name = '' WHERE name IS NULL"
    execute "UPDATE games SET code = 'mtg' WHERE code IS NULL"

    alter table(:games) do
      modify :name, :string, null: false
      modify :code, :string, null: false
    end

    # Tournaments
    execute "DELETE FROM tournaments WHERE game_id IS NULL"
    execute "UPDATE tournaments SET format = 'edh' WHERE format IS NULL"
    execute "UPDATE tournaments SET subformat = 'bubble_rounds' WHERE subformat IS NULL"
    execute "UPDATE tournaments SET status = 'inactive' WHERE status IS NULL"
    execute "UPDATE tournaments SET round_length_minutes = 60 WHERE round_length_minutes IS NULL"
    execute "UPDATE tournaments SET is_top_cut_4 = false WHERE is_top_cut_4 IS NULL"
    execute "UPDATE tournaments SET round_count = 4 WHERE round_count IS NULL"

    alter table(:tournaments) do
      modify :game_id, :bigint, null: false
      modify :format, :string, null: false, default: "edh"
      modify :subformat, :string, null: false, default: "bubble_rounds"
      modify :status, :string, null: false, default: "inactive"
      modify :round_length_minutes, :integer, null: false, default: 60
      modify :is_top_cut_4, :boolean, null: false, default: false
      modify :round_count, :integer, null: false, default: 4
    end
  end

  def down do
    alter table(:pairings) do
      modify :round_id, :bigint, null: true
      modify :tournament_id, :bigint, null: true
    end

    alter table(:pairing_participants) do
      modify :participant_id, :bigint, null: true
      modify :pairing_id, :bigint, null: true
    end

    alter table(:rounds) do
      modify :tournament_id, :bigint, null: true
      modify :status, :string, null: true, default: nil
    end

    alter table(:games) do
      modify :name, :string, null: true
      modify :code, :string, null: true
    end

    alter table(:tournaments) do
      modify :game_id, :bigint, null: true
      modify :format, :string, null: true, default: nil
      modify :subformat, :string, null: true, default: nil
      modify :status, :string, null: true, default: nil
      modify :round_length_minutes, :integer, null: true, default: nil
      modify :is_top_cut_4, :boolean, null: true, default: nil
      modify :round_count, :integer, null: true, default: nil
    end
  end
end
