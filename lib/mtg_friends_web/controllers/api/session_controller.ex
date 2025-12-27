defmodule MtgFriendsWeb.API.SessionController do
  use MtgFriendsWeb, :controller

  use OpenApiSpex.ControllerSpecs

  alias MtgFriends.Accounts
  alias MtgFriendsWeb.Schemas

  tags ["sessions"]

  operation :create,
    summary: "Login",
    security: [],
    request_body: {"Login params", "application/json", Schemas.LoginRequest},
    responses: [
      created: {"Login successful", "application/json", Schemas.LoginResponse},
      unauthorized: {"Invalid credentials", "application/json", Schemas.ErrorResponse}
    ]

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
