defmodule MtgFriends.Repo.Migrations.AddAdminFlagToUsers do
  use Ecto.Migration
  import Ecto.Query

  alias MtgFriends.Repo

  def change do
    alter table(:users) do
      add :admin, :boolean, default: false, null: false
    end

    flush()

    Repo.get_by!(MtgFriends.Accounts.User, email: "timrodz@icloud.com")
    |> IO.inspect()
    |> Ecto.Changeset.change(%{admin: true})
    |> MtgFriends.Repo.update()
  end
end
