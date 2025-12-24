defmodule MtgFriendsWeb.API.TournamentJSON do
  alias MtgFriends.Tournaments.Tournament

  @doc """
  Renders a list of tournaments.
  """
  def index(%{tournaments: tournaments}) do
    %{data: for(tournament <- tournaments, do: data(tournament))}
  end

  @doc """
  Renders a single tournament.
  """
  def show(%{tournament: tournament}) do
    %{data: data(tournament)}
  end

  defp data(%Tournament{} = tournament) do
    %{
      id: tournament.id,
      name: tournament.name,
      date: tournament.date,
      status: tournament.status,
      description_html: tournament.description_html
    }
  end
end
