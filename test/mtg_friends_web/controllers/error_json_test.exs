defmodule MtgFriendsWeb.ErrorJSONTest do
  use MtgFriendsWeb.ConnCase, async: true

  test "renders changeset errors" do
    data = %{}
    types = %{name: :string, count: :integer}

    changeset =
      Ecto.Changeset.cast({data, types}, %{count: "invalid"}, [:name, :count])
      |> Ecto.Changeset.validate_required([:name])

    assert %{errors: errors} =
             MtgFriendsWeb.ErrorJSON.render("error.json", %{changeset: changeset})

    assert errors.name == ["can't be blank"]
    assert errors.count == ["is invalid"]
  end
end
