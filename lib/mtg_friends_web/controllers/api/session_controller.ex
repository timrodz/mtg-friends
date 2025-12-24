defmodule MtgFriendsWeb.API.SessionController do
  use MtgFriendsWeb, :controller

  alias MtgFriends.Accounts

  def create(conn, %{"email" => email, "password" => password}) do
    if user = Accounts.get_user_by_email_and_password(email, password) do
      token = Accounts.generate_user_session_token(user) |> Base.url_encode64(padding: false)

      conn
      |> put_status(:created)
      |> json(%{
        data: %{
          token: token,
          user: %{
            id: user.id,
            email: user.email
          }
        }
      })
    else
      conn
      |> put_status(:unauthorized)
      |> json(%{error: "Invalid email or password"})
    end
  end
end
