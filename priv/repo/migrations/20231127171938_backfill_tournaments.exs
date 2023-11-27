defmodule MtgFriends.Repo.Migrations.BackfillTournaments do
  use Ecto.Migration
  import Ecto.Query

  alias MtgFriends.Tournaments.Tournament
  alias MtgFriends.Repo

  @disable_ddl_transaction true
  @disable_migration_lock true

  def up do
    Ecto.Multi.new()
    |> Ecto.Multi.update_all(:update_all, Tournament,
      set: [status: :inactive, format: :edh, subformat: :bubble_rounds]
    )
    |> Repo.transaction()
  end

  def down, do: :ok
end
