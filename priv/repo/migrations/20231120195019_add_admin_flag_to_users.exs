defmodule MtgFriends.Repo.Migrations.AddAdminFlagToUsers do
  use Ecto.Migration
  import Ecto.Query

  alias MtgFriends.Repo

  def change do
    alter table(:users) do
      add :admin, :boolean, default: false, null: false
    end

    flush()

    case Repo.get_by(MtgFriends.Accounts.User, email: "timrodz@icloud.com") do
      # User doesn't exist, skip
      nil ->
        :ok

      user ->
        user
        |> Ecto.Changeset.change(%{admin: true})
        |> MtgFriends.Repo.update()
    end
  end
end
