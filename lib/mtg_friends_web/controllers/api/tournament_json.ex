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

  alias MtgFriendsWeb.API.ParticipantJSON
  alias MtgFriendsWeb.API.RoundJSON

  defp data(%Tournament{} = tournament) do
    participants =
      if Ecto.assoc_loaded?(tournament.participants) do
        for p <- tournament.participants, do: ParticipantJSON.data(p)
      else
        []
      end

    rounds =
      if Ecto.assoc_loaded?(tournament.rounds) do
        for r <- tournament.rounds, do: RoundJSON.data(r)
      else
        []
      end

    %{
      id: tournament.id,
      name: tournament.name,
      user_id: tournament.user_id,
      game_id: tournament.game_id,
      date: tournament.date,
      location: tournament.location,
      status: tournament.status,
      description_raw: tournament.description_raw,
      description_html: tournament.description_html,
      round_length_minutes: tournament.round_length_minutes,
      round_count: tournament.round_count,
      format: tournament.format,
      subformat: tournament.subformat,
      is_top_cut_4: tournament.is_top_cut_4,
      participants: participants,
      rounds: rounds
    }
  end
end
