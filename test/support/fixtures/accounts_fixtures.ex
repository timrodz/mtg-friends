defmodule MtgFriends.AccountsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `MtgFriends.Accounts` context.
  """

  def unique_user_email, do: "user#{System.unique_integer()}@example.com"
  def valid_user_password, do: "hello world!"

  def valid_user_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      email: unique_user_email(),
      password: valid_user_password()
    })
  end

  def user_fixture(attrs \\ %{}) do
    admin = Map.get(attrs, :admin, false)
    attrs = Map.delete(attrs, :admin)

    {:ok, user} =
      attrs
      |> valid_user_attributes()
      |> MtgFriends.Accounts.register_user()

    if admin do
      user
      |> Ecto.Changeset.change(%{admin: true})
      |> MtgFriends.Repo.update!()
    else
      user
    end
  end

  def extract_user_token(fun) do
    {:ok, captured_email} = fun.(&"[TOKEN]#{&1}[TOKEN]")
    [_, token | _] = String.split(captured_email.text_body, "[TOKEN]")
    token
  end
end
