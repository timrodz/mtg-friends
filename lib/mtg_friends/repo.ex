defmodule MtgFriends.Repo do
  use Ecto.Repo,
    otp_app: :mtg_friends,
    adapter: Ecto.Adapters.Postgres
end
