defmodule MtgFriendsWeb.Live.TournamentLive.Utils do
  def assign_current_user_tournament_owner(socket, current_user, tournament) do
    Phoenix.Component.assign(
      socket,
      :is_current_user_tournament_owner,
      not is_nil(current_user) && current_user.id == tournament.user_id
    )
  end
end
