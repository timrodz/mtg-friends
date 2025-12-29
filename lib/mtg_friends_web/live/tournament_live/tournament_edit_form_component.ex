defmodule MtgFriendsWeb.TournamentLive.TournamentEditFormComponent do
  alias MtgFriends.Games
  alias MtgFriends.Participants
  use MtgFriendsWeb, :live_component

  alias MtgFriends.Tournaments

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
      </.header>

      <.simple_form
        for={@form}
        id="tournament-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input
          field={@form[:game_code]}
          type="select"
          label="Game"
          options={@game_codes}
          value={@selected_game_code}
        />
        <.input field={@form[:format]} type="select" options={@format_options} label="Format" />
        <.input field={@form[:name]} type="text" label="Name" min="4" />
        <.input field={@form[:location]} type="text" label="Location" min="4" />
        <.input field={@form[:date]} type="datetime-local" label="Date" />

        <.input
          :if={@action == :edit}
          field={@form[:status]}
          type="select"
          label="Status"
          options={[
            {"1. Open (registering participants)", "inactive"},
            {"2. In progress (tournament started)", "active"},
            {"3. Finished", "finished"}
          ]}
        />
        <.input field={@form[:description_raw]} type="textarea" label="Description" />
        <.input
          field={@form[:round_length_minutes]}
          type="number"
          label="Round duration (Minutes; Min: 30 / Max: 120)"
          min="30"
          max="120"
        />
        <.input
          field={@form[:round_count]}
          type="number"
          label="Number of rounds (Min: 3 / Max: 10)"
          min="3"
          max="10"
        />
        <.input
          :if={@action == :new}
          required
          type="textarea"
          label="Participants (One per line)"
          field={@form[:initial_participants]}
          placeholder="John Doe
    Jane Doe
    ---"
        />
        <.input
          field={@form[:subformat]}
          type="select"
          options={@subformat_options}
          label="Round pairing algorithm"
        />
        <.input
          :if={@selected_game_code == :mtg}
          field={@form[:is_top_cut_4]}
          type="checkbox"
          label="Top Cut 4 (Has a final round decided by the top 4 players)"
          class="mt-2"
        />
        <:actions>
          <.button phx-disable-with="Saving..." variant="primary">
            <.icon name="hero-rocket-launch-solid" /> Submit Tournament
          </.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{tournament: tournament} = assigns, socket) do
    changeset =
      Tournaments.change_tournament(
        tournament,
        case tournament.date do
          nil -> %{date: NaiveDateTime.local_now()}
          _ -> %{}
        end
      )

    selected_game_code = if tournament.game_id, do: tournament.game.code, else: :mtg

    selected_format = tournament.format || :edh

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:game_codes, get_game_codes())
     |> assign(:selected_game_code, selected_game_code)
     |> assign(:format_options, get_format_options(selected_game_code))
     |> assign(
       :subformat_options,
       get_subformat_options(selected_game_code, selected_format)
     )
     |> assign(:initial_participants, "")
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"tournament" => tournament_params}, socket) do
    selected_game_code =
      tournament_params["game_code"] |> String.to_atom()

    format_options = get_format_options(selected_game_code)

    selected_format =
      case socket.assigns.selected_game_code != selected_game_code do
        # Changed games, select the first format option
        true ->
          format_options |> Enum.at(0) |> elem(1)

        false ->
          tournament_params["format"] |> String.to_atom()
      end

    subformat_options =
      get_subformat_options(selected_game_code, selected_format)

    changeset =
      socket.assigns.tournament
      |> Tournaments.change_tournament(tournament_params)
      |> Map.put(:action, :validate)

    {:noreply,
     socket
     |> assign_form(changeset)
     |> assign(:selected_game_code, selected_game_code)
     |> assign(:format_options, format_options)
     |> assign(:subformat_options, subformat_options)}
  end

  def handle_event("save", %{"tournament" => tournament_params}, socket) do
    save_tournament(socket, socket.assigns.action, tournament_params)
  end

  defp save_tournament(socket, :edit, tournament_params) do
    tournament = socket.assigns.tournament

    # This could be optimized but we're chilling for now
    game = Games.get_game_by_code!(socket.assigns.selected_game_code)

    tournament_params =
      tournament_params
      |> Map.put("game_id", game.id)

    case Tournaments.update_tournament(tournament, tournament_params) do
      {:ok, updated_tournament} ->
        notify_parent({:saved, updated_tournament})

        {:noreply,
         cond do
           path = Map.get(socket.assigns, :navigate) ->
             socket
             |> put_flash(:success, "Tournament updated successfully")
             |> push_navigate(to: path)

           true ->
             socket
             |> put_flash(:success, "Tournament updated successfully")
             |> push_navigate(to: ~p"/tournaments/#{updated_tournament}")
         end}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_tournament(socket, :new, tournament_params) do
    game = Games.get_game_by_code!(socket.assigns.selected_game_code)

    tournament_params =
      tournament_params
      |> Map.put("user_id", socket.assigns.current_user.id)
      |> Map.put("game_id", game.id)

    case Tournaments.create_tournament(tournament_params) do
      {:ok, tournament} ->
        notify_parent({:saved, tournament})

        case Participants.create_x_participants(
               tournament.id,
               tournament_params["initial_participants"]
               |> String.split("\n", trim: true)
             ) do
          {:ok, _} ->
            {:noreply,
             socket
             |> put_flash(:success, "Tournament created successfully")
             |> push_navigate(to: "/tournaments/#{tournament.id}")}

          _ ->
            {:noreply, socket}
        end

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp get_game_codes() do
    [
      {"Magic: The Gathering", :mtg},
      {"Yu-Gi-Oh!", :yugioh},
      {"Pokémon", :pokemon}
    ]
  end

  defp get_format_options(game_code) do
    case game_code do
      :mtg ->
        [{"Commander (EDH)", :edh}]

      _ ->
        [{"Standard", :standard}]
    end
  end

  defp get_subformat_options(game_code, format) do
    # This can expand later on, keep it somewhat "complex" for now
    case game_code do
      :mtg ->
        case format do
          :edh ->
            [
              {"Bubble Rounds (Pods are determined by last round standings)", :bubble_rounds},
              {"Swiss Rounds", :swiss}
            ]

          _ ->
            [{"Swiss Rounds", :swiss}]
        end

      _ ->
        [{"Swiss Rounds", :swiss}]
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
