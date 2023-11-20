defmodule MtgFriends.Tournaments do
  @moduledoc """
  The Tournaments context.
  """

  import Ecto.Query, warn: false
  alias MtgFriends.Repo

  alias MtgFriends.Tournaments.Tournament
  alias MtgFriends.Rounds.Round
  alias MtgFriends.Participants.Participant

  @doc """
  Returns the list of tournaments.

  ## Examples

      iex> list_tournaments()
      [%Tournament{}, ...]

  """
  def list_tournaments(params \\ {}) do
    case params do
      "filter-inactive" ->
        Repo.all(from(t in Tournament, where: [active: false], select: t))

      "filter-active" ->
        Repo.all(from(t in Tournament, where: [active: true], select: t))

      _ ->
        Repo.all(Tournament, order_by: [desc: :date])
    end
  end

  def list_tournaments_admin() do
    Repo.all(Tournament, order_by: [asc: :id])
    |> Repo.preload([:participants, :rounds])
  end

  @doc """
  Gets a single tournament.

  Raises `Ecto.NoResultsError` if the Tournament does not exist.

  ## Examples

      iex> get_tournament!(123)
      %Tournament{}

      iex> get_tournament!(456)
      ** (Ecto.NoResultsError)

  """

  # def get_tournament!(id),
  #   do:
  #     Repo.get!(Tournament, id)
  #     |> Repo.preload([:participants])

  def get_tournament!(id) do
    query =
      from(
        t in Tournament,
        where: t.id == ^id,
        select: t,
        preload: [
          participants: ^from(p in Participant, order_by: [asc: p.id]),
          rounds: ^from(r in Round, order_by: [asc: r.id], preload: :pairings)
        ]
      )

    Repo.one!(query)
  end

  @doc """
  Creates a tournament.

  ## Examples

      iex> create_tournament(%{field: value})
      {:ok, %Tournament{}}

      iex> create_tournament(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_tournament(attrs \\ %{}) do
    %Tournament{}
    |> Tournament.changeset(Map.put(attrs, "description_html", validate_description(attrs)))
    |> Repo.insert()
  end

  @doc """
  Updates a tournament.

  ## Examples

      iex> update_tournament(tournament, %{field: new_value})
      {:ok, %Tournament{}}

      iex> update_tournament(tournament, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_tournament(%Tournament{} = tournament, attrs) do
    tournament
    |> Tournament.changeset(attrs)
    |> Ecto.Changeset.put_change(:description_html, validate_description(attrs))
    |> Repo.update()
  end

  @doc """
  Deletes a tournament.

  ## Examples

      iex> delete_tournament(tournament)
      {:ok, %Tournament{}}

      iex> delete_tournament(tournament)
      {:error, %Ecto.Changeset{}}

  """
  def delete_tournament(%Tournament{} = tournament) do
    Repo.delete(tournament)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking tournament changes.

  ## Examples

      iex> change_tournament(tournament)
      %Ecto.Changeset{data: %Tournament{}}

  """
  def change_tournament(%Tournament{} = tournament, attrs \\ %{}) do
    Tournament.changeset(tournament, attrs)
  end

  defp validate_description(attrs) do
    with description_raw <- Map.get(attrs, "description_raw"),
         true <- String.length(description_raw) > 0 do
      IO.puts("leshgo")
      HTTPoison.start()

      cards_to_search =
        Regex.scan(~r/\[\[(.*?)\]\]/, description_raw)
        |> Enum.map(&hd/1)
        |> then(
          &for(
            card <- &1,
            do:
              case HTTPoison.get(
                     "https://api.scryfall.com/cards/named?fuzzy=#{card |> String.replace("[[", "") |> String.replace("]]", "")}"
                   ) do
                {:ok, response} ->
                  expected_fields = ~w(image_uris name scryfall_uri)

                  body =
                    response.body
                    |> Poison.decode!()
                    |> Map.take(expected_fields)

                  image_uris = Map.get(body, "image_uris")
                  img_large = Map.get(image_uris, "large")
                  name = Map.get(body, "name")
                  %{image_uri: img_large, name: name, og_name: "[[#{name}]]"}
              end
          )
        )

      cards_names_to_search = for card <- cards_to_search, do: card.og_name

      String.replace(
        String.replace(description_raw, "\n", "</br>"),
        cards_names_to_search,
        fn og_name ->
          metadata = Enum.find(cards_to_search, fn card -> card.og_name == og_name end)

          "<a class=\"underline\" target=\"_blank\" href=\"#{metadata.image_uri}\">#{metadata.name}</a>"
        end
      )
    else
      _ -> ""
    end
  end
end
