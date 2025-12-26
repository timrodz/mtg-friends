defmodule MtgFriendsWeb.FallbackController do
  @moduledoc """
  Translates controller action results into valid `Plug.Conn` responses.

  See `Phoenix.Controller.action_fallback/1` for more details.
  """
  use MtgFriendsWeb, :controller

  # This clause handles errors returned by Ecto's transaction-like methods.
  def call(conn, {:error, %Ecto.Changeset{} = changeset}) do
    conn
    |> put_status(:unprocessable_entity)
    |> put_view(json: MtgFriendsWeb.ErrorJSON)
    |> render(:error, changeset: changeset)
  end

  # This clause handles cases where a record is not found.
  def call(conn, {:error, :not_found}) do
    conn
    |> put_status(:not_found)
    |> put_view(json: MtgFriendsWeb.ErrorJSON)
    |> render(:"404")
  end

  # This clause handles unauthorized access.
  def call(conn, {:error, :unauthorized}) do
    conn
    |> put_status(:unauthorized)
    |> put_view(json: MtgFriendsWeb.ErrorJSON)
    |> render(:"401")
  end

  # This clause handles forbidden access.
  def call(conn, {:error, :forbidden}) do
    conn
    |> put_status(:forbidden)
    |> put_view(json: MtgFriendsWeb.ErrorJSON)
    |> render(:"403")
  end

  # This clause handles conflicts.
  def call(conn, {:error, :conflict}) do
    conn
    |> put_status(:conflict)
    |> put_view(json: MtgFriendsWeb.ErrorJSON)
    |> render(:"409")
  end
end
