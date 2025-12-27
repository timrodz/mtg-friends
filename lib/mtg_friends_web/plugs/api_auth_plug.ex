defmodule MtgFriendsWeb.APIAuthPlug do
  import Plug.Conn
  alias MtgFriends.Accounts

  def init(opts), do: opts

  def call(conn, _opts) do
    if conn.assigns[:current_user] do
      conn
    else
      with ["Bearer " <> token] <- get_req_header(conn, "authorization"),
           {:ok, decoded_token} <- Base.url_decode64(token, padding: false),
           user when not is_nil(user) <- Accounts.get_user_by_session_token(decoded_token) do
        assign(conn, :current_user, user)
      else
        _ ->
          conn
          |> send_resp(401, "Unauthorized")
          |> halt()
      end
    end
  end
end
