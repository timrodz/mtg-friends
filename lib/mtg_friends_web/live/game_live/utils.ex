defmodule MtgFriendsWeb.Live.GameLive.Utils do
  def render_name(game_code) do
    case game_code do
      :mtg -> "Magic: The Gathering"
    end
  end
end
