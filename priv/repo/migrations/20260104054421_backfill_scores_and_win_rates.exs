defmodule MtgFriends.Repo.Migrations.BackfillScoresAndWinRates do
  use Ecto.Migration

  alias MtgFriends.Repo
  import Ecto.Query

  def up do
    # Ensure the code is compiled and available
    # We can query all tournaments

    # We need to run this outside of a transaction if the logic inside uses transactions
    # But Ecto migrations are wrapped in transactions by default unless `disable_ddl_transaction: true`
    # However, `calculate_and_update_scores` uses `Repo.transaction`. Nested transactions are fine in Ecto (savepoints).

    # Using a simple query to get IDs avoiding schema dependency issues in migrations if possible,
    # but for this logic we need the App code effectively.
    # Note: Using application logic in migrations is risky if code changes later.
    # A safer way is to copy logic or just `Repo.query` but since we just wrote the logic, let's use it.

    # To avoid Schema compilation issues if this migration runs in future,
    # usually better to write raw SQL or redundant logic here.
    # But for now, we will assume code availability.

    # We'll just define a minimal query
    tournaments = Repo.all(from(t in "tournaments", select: t.id))

    Enum.each(tournaments, fn tournament_id ->
      MtgFriends.Participants.calculate_and_update_scores(tournament_id)
    end)
  end

  def down do
    # No-op, or set win_rate to 0.0
    execute "UPDATE participants SET win_rate = 0.0, points = 0"
  end
end
