defmodule MtgFriends.Repo.Migrations.PopulateGames do
  use Ecto.Migration

  import Ecto.Multi

  alias MtgFriends.Tournaments.Tournament
  alias MtgFriends.Games.Game
  alias MtgFriends.Games
  alias MtgFriends.Repo

  def up do
    now = NaiveDateTime.local_now()

    results =
      Ecto.Multi.new()
      |> Ecto.Multi.insert_all(:insert_all, Game, [
        %{
          name: "Magic: The Gathering",
          code: :mtg,
          url: "",
          inserted_at: now,
          updated_at: now
        },
        %{
          name: "Yu-Gi-Oh!",
          code: :yugioh,
          url: "",
          inserted_at: now,
          updated_at: now
        },
        %{
          name: "Pokémon",
          code: :pokemon,
          url: "",
          inserted_at: now,
          updated_at: now
        }
      ])
      |> Repo.transaction()

    flush()

    mtg = Games.get_game_by_code!("mtg")

    Ecto.Multi.new()
    |> Ecto.Multi.update_all(:update_all, Tournament, set: [game_id: mtg.id])
    |> MtgFriends.Repo.transaction()
  end

  def down do
    :ok
  end
end
