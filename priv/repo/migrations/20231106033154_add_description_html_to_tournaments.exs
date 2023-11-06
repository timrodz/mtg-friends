defmodule MtgFriends.Repo.Migrations.AddDescriptionHtmlToTournaments do
  use Ecto.Migration
  import Ecto.Query

  def change do
    alter table(:tournaments) do
      add :description_html, :text
    end
  end
end
