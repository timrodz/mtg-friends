defmodule ValidationHelper do
  alias Ecto.Changeset

  @doc "helper to allow empty strings as field values
  must be called BEFORE cast to have any effect.
  "
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
  def stringify_value(attrs, key) do
    if Map.has_key?(attrs, key) do
      Map.put(attrs, key, to_string(attrs.key))
    else
      attrs
    end
  end

  def validate_url(changeset, field, opts \\ []) do
    Ecto.Changeset.validate_change(changeset, field, fn _, value ->
      case URI.parse(value) do
        %URI{scheme: nil} ->
          Ecto.Changeset.add_error(changeset, field, "is missing a scheme (e.g. https)")

        %URI{host: nil} ->
          Ecto.Changeset.add_error(changeset, field, "is missing a host (e.g. .com)")

        %URI{host: host} ->
          case :inet.gethostbyname(Kernel.to_charlist(host)) do
            {:ok, _} ->
              changeset

            {:error, _} ->
              Ecto.Changeset.add_error(changeset, field, "has an invalid host")
          end
      end
    end)
  end
end
