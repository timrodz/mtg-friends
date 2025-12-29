defmodule MtgFriends.Tournaments do
  @moduledoc """
  The Tournaments context.
  """

  import Ecto.Query, warn: false
  alias MtgFriends.Repo

  alias MtgFriends.Tournaments.Tournament
  alias MtgFriends.Rounds.Round
  alias MtgFriends.Participants.Participant

  def get_most_recent_tournaments(limit) do
    from(t in Tournament, order_by: [desc: :date], limit: ^limit, preload: [:game]) |> Repo.all()
  end

  @doc """
  Returns the list of tournaments.

  ## Examples

      iex> list_tournaments()
      [%Tournament{}, ...]

  """
  def list_tournaments(params \\ {}) do
    case params do
      "filter-inactive" ->
        from(t in Tournament, where: t.status in [:inactive, :finished]) |> Repo.all()

      "filter-active" ->
        from(t in Tournament, where: t.status == :active, select: t) |> Repo.all()

      _ ->
        Repo.all(Tournament, order_by: [desc: :date])
    end
  end

  def list_tournaments_paginated(limit \\ 6, page \\ 1) do
    offset = limit * (page - 1)

    from(t in Tournament,
      select: t,
      order_by: [desc: :date],
      limit: ^limit,
      offset: ^offset,
      preload: [:game]
    )
    |> Repo.all()
  end

  def get_tournament_count() do
    Repo.aggregate(Tournament, :count, :id)
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
          :game,
          participants: ^from(p in Participant, order_by: [asc: p.id]),
          rounds: ^from(r in Round, order_by: [asc: r.id], preload: :pairings)
        ]
      )

    Repo.one!(query)
  end

  def get_tournament_simple(id), do: Repo.get(Tournament, id)
  def get_tournament_simple!(id), do: Repo.get!(Tournament, id)

  def has_enough_participants?(%Tournament{participants: participants})
      when is_list(participants) do
    length(participants) >= 4
  end

  def has_enough_participants?(%Tournament{} = tournament) do
    tournament = Repo.preload(tournament, :participants)
    length(tournament.participants) >= 4
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
    |> Tournament.changeset(
      with description_raw <- Map.get(attrs, "description_raw"),
           false <- is_nil(description_raw),
           true <- String.length(description_raw) > 0 do
        attrs
        |> Map.put(
          "description_html",
          validate_description(description_raw)
        )
      else
        _ ->
          attrs
      end
    )
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
    with description_raw <- Map.get(attrs, "description_raw"),
         false <- is_nil(description_raw),
         true <- String.length(description_raw) > 0 do
      tournament
      |> Tournament.changeset(attrs)
      |> Ecto.Changeset.put_change(:description_html, validate_description(description_raw))
      |> Repo.update()
    else
      _ ->
        tournament
        |> Tournament.changeset(attrs)
        |> Ecto.Changeset.put_change(:description_html, "")
        |> Repo.update()
    end
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

  defp validate_description(description_raw) do
    try do
      HTTPoison.start()
      expected_fields = ~w(image_uris name)

      # Grabs all text inside double brackets i.e. [[Lightning greaves]]
      cards_to_search =
        Regex.scan(~r/\[\[(.*?)\]\]/, description_raw)
        |> Enum.map(&hd/1)
        |> then(
          &for(
            card_raw <- &1,
            do:
              with card_clean <-
                     card_raw
                     |> String.replace("[[", "")
                     |> String.replace("]]", "")
                     |> URI.encode(),
                   uri <-
                     "https://api.scryfall.com/cards/named?fuzzy=#{card_clean}",
                   {:ok, response} <-
                     HTTPoison.get(
                       uri,
                       [
                         {"User-Agent", "tie-breaker/#{Application.spec(:mtg_friends, :vsn)}"},
                         {"Accept", "application/json"}
                       ]
                     ) do
                body =
                  response.body
                  |> Poison.decode!()
                  |> Map.take(expected_fields)

                image_uris = Map.get(body, "image_uris")
                img_large = Map.get(image_uris, "large")
                name = Map.get(body, "name")

                %{image_uri: img_large, name: name, og_name: card_raw}
              else
                _ -> nil
              end
          )
        )
        |> Enum.reject(&is_nil/1)

      cards_names_to_search = for card <- cards_to_search, do: card.og_name

      String.replace(
        String.replace(description_raw, "\n", "</br>"),
        cards_names_to_search,
        fn og_name ->
          metadata = Enum.find(cards_to_search, fn card -> card.og_name == og_name end)

          "<a class=\"underline\" target=\"_blank\" href=\"#{metadata.image_uri}\">#{metadata.name}</a>"
        end
      )
    rescue
      _ ->
        String.replace(description_raw, "\n", "</br>")
    end
  end
end
