defmodule ValidationHelper do
  alias Ecto.Changeset

  @doc "helper to allow empty strings as field values
  must be called BEFORE cast to have any effect.
  "
  @spec allow_empty_strings(Ecto.Changeset.t()) :: Ecto.Changeset.t()
  def allow_empty_strings(%Changeset{valid?: false}) do
    raise ArgumentError, "Cannot allow empty strings on a Changeset after cast has been called"
  end

  def allow_empty_strings(%Changeset{changes: %{}} = changeset) do
    Map.put(changeset, :empty_values, [])
  end

  def allow_empty_strings(_changeset) do
    raise ArgumentError, "Cannot allow empty strings on a Changeset after cast has been called"
  end

  @doc "convert specified field to_string if it exists"
  @spec stringify_value(map(), atom()) :: map()
  def stringify_value(attrs, key) do
    if Map.has_key?(attrs, key) do
      Map.put(attrs, key, to_string(attrs.key))
    else
      attrs
    end
  end
end
