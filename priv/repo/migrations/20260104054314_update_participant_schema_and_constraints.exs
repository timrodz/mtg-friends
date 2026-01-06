defmodule MtgFriends.Repo.Migrations.UpdateParticipantSchemaAndConstraints do
  use Ecto.Migration

  def up do
    # Add win_rate as nullable first
    alter table(:participants) do
      add :win_rate, :float
    end

    # Update Data to satisfy constraints
    execute "UPDATE participants SET win_rate = 0.0"
    execute "UPDATE participants SET points = 0 WHERE points IS NULL"
    execute "UPDATE participants SET name = '' WHERE name IS NULL"
    execute "UPDATE participants SET is_dropped = false WHERE is_dropped IS NULL"

    execute "UPDATE participants SET is_tournament_winner = false WHERE is_tournament_winner IS NULL"

    # Set Not Null constraints and defaults
    alter table(:participants) do
      modify :win_rate, :float, null: false, default: 0.0
      modify :points, :integer, null: false, default: 0
      modify :name, :string, null: false, default: ""
      modify :is_dropped, :boolean, null: false, default: false
      modify :is_tournament_winner, :boolean, null: false, default: false

      # Modify tournament_id to be not null, checking existing data is assumed safe based on foreign key usually
      modify :tournament_id, :bigint, null: false
    end
  end

  def down do
    alter table(:participants) do
      modify :points, :integer, null: true
      modify :name, :string, null: true, default: nil
      modify :is_dropped, :boolean, null: true, default: nil
      modify :is_tournament_winner, :boolean, null: true, default: nil
      modify :tournament_id, :bigint, null: true
      remove :win_rate
    end
  end
end
