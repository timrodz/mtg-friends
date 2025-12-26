defmodule MtgFriendsWeb.Plugs.AuthorizeTournamentOwner do
  @moduledoc """
  Plug to authorize that the current user is the owner of the tournament.
  Expected tournament_id in conn.params.
  """
  import Plug.Conn
  import Phoenix.Controller

  alias MtgFriends.Tournaments

  def init(opts), do: opts

  def call(conn, _opts) do
    tournament_id = conn.params["tournament_id"]
    current_user = conn.assigns[:current_user]

    if is_nil(current_user) do
      conn
      |> put_status(:unauthorized)
      |> put_view(json: MtgFriendsWeb.ErrorJSON)
      |> render(:"401")
      |> halt()
    else
      case Tournaments.get_tournament_simple(tournament_id) do
        %MtgFriends.Tournaments.Tournament{user_id: user_id} = tournament ->
          if user_id == current_user.id do
            assign(conn, :tournament, tournament)
          else
            halt_unauthorized(conn)
          end

        nil ->
          halt_not_found(conn)
      end
    end
  end

  defp halt_unauthorized(conn) do
    conn
    |> put_status(:forbidden)
    |> put_view(json: MtgFriendsWeb.ErrorJSON)
    |> render(:"403")
    |> halt()
  end

  defp halt_not_found(conn) do
    conn
    |> put_status(:not_found)
    |> put_view(json: MtgFriendsWeb.ErrorJSON)
    |> render(:"404")
    |> halt()
  end
end
