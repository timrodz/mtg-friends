defmodule MtgFriends.Games do
  @moduledoc """
  The Games context.
  """

  import Ecto.Query, warn: false
  alias MtgFriends.Repo

  alias MtgFriends.Games.Game

  @doc """
  Returns the list of games.

  ## Examples

      iex> list_games()
      [%Game{}, ...]

  """
  @spec list_games() :: [Game.t()]
  def list_games do
    Repo.all(Game)
  end

  @doc """
  Gets a single game.

  Raises `Ecto.NoResultsError` if the Game does not exist.

  ## Examples

      iex> get_game!(123)
      %Game{}

      iex> get_game!(456)
      ** (Ecto.NoResultsError)

  """
  @spec get_game!(integer()) :: Game.t() | no_return()
  def get_game!(id), do: Repo.get!(Game, id)
  @spec get_game_by_code!(String.t()) :: Game.t() | no_return()
  def get_game_by_code!(code), do: Repo.get_by!(Game, code: code)
  @spec get_game_by_code(String.t()) :: Game.t() | nil
  def get_game_by_code(code), do: Repo.get_by(Game, code: code)

  @doc """
  Creates a game.

  ## Examples

      iex> create_game(%{field: value})
      {:ok, %Game{}}

      iex> create_game(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec create_game(map()) :: {:ok, Game.t()} | {:error, Ecto.Changeset.t()}
  def create_game(attrs \\ %{}) do
    %Game{}
    |> Game.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a game.

  ## Examples

      iex> update_game(game, %{field: new_value})
      {:ok, %Game{}}

      iex> update_game(game, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec update_game(Game.t(), map()) :: {:ok, Game.t()} | {:error, Ecto.Changeset.t()}
  def update_game(%Game{} = game, attrs) do
    game
    |> Game.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a game.

  ## Examples

      iex> delete_game(game)
      {:ok, %Game{}}

      iex> delete_game(game)
      {:error, %Ecto.Changeset{}}

  """
  @spec delete_game(Game.t()) :: {:ok, Game.t()} | {:error, Ecto.Changeset.t()}
  def delete_game(%Game{} = game) do
    Repo.delete(game)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking game changes.

  ## Examples

      iex> change_game(game)
      %Ecto.Changeset{data: %Game{}}

  """
  @spec change_game(Game.t(), map()) :: Ecto.Changeset.t()
  def change_game(%Game{} = game, attrs \\ %{}) do
    Game.changeset(game, attrs)
  end
end
