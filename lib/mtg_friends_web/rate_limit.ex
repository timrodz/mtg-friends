defmodule MtgFriendsWeb.RateLimit do
  use Hammer, backend: :ets
end
