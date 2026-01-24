defmodule MtgFriends.Repo.Migrations.AddRoundRobinToSubformat do
  use Ecto.Migration

  @moduledoc """
  Migration for round_robin subformat support.

  The subformat field is stored as a string in Postgres, not as a Postgres enum type.
  Adding a new value only requires updating the Ecto.Enum in the schema (tournament.ex).
  This migration serves as documentation of the change.
  """

  def up do
    :ok
  end

  def down do
    :ok
  end
end
