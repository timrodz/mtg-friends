defmodule MtgFriendsWeb.TournamentLive.TournamentEditFormComponent do
  alias MtgFriends.Participants
  use MtgFriendsWeb, :live_component

  alias MtgFriends.Tournaments

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
      </.header>

      <.simple_form
        for={@form}
        id="tournament-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:name]} type="text" label="Name" />
        <.input field={@form[:location]} type="text" label="Location" />
        <.input field={@form[:date]} type="datetime-local" label="Date" />
        <.input
          :if={@action == :edit}
          field={@form[:status]}
          type="select"
          options={[
            {"1. Open (registering participants)", "inactive"},
            {"2. In progress (tournament started)", "active"},
            {"3. Finished", "finished"}
          ]}
          label="Status"
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
        <%= if @action == :new do %>
          <.input
            field={@form[:participant_count]}
            type="number"
            label="Number of participants (Min: 4 / Max: 24)"
            value={@participant_count}
            phx-change="update-participant-count"
            min="4"
            max="24"
          />
          <.input
            field={@form[:format]}
            type="select"
            options={[
              {"EDH", "edh"}
            ]}
            label="Format"
          />
        <% end %>
        <.input
          field={@form[:subformat]}
          type="select"
          options={@subformat_options}
          label="Round Method"
        />
        <.input
          field={@form[:is_top_cut_4]}
          type="checkbox"
          label="Top Cut 4 (Has a final round decided by the top 4 players)"
        />
        <:actions>
          <.button phx-disable-with="Saving...">Submit Tournament</.button>
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

    {:ok,
     socket
     |> assign(assigns)
     # EDH is the default format
     |> assign(:subformat_options, get_subformat_options("edh"))
     |> assign(:participant_count, 8)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"tournament" => tournament_params}, socket) do
    selected_format =
      case tournament_params["format"] do
        # No format found in the form's params, that means the taournament already exists
        nil ->
          socket.assigns.tournament.format

        _ ->
          tournament_params["format"]
      end

    changeset =
      socket.assigns.tournament
      |> Tournaments.change_tournament(tournament_params)
      |> Map.put(:action, :validate)

    {:noreply,
     socket
     |> assign_form(changeset)
     |> assign(:subformat_options, get_subformat_options(selected_format))}
  end

  @impl true
  def handle_event(
        "update-participant-count",
        %{"tournament" => %{"participant_count" => count}},
        socket
      ) do
    {:noreply,
     socket
     |> assign(:participant_count, count)}
  end

  def handle_event("save", %{"tournament" => tournament_params}, socket) do
    save_tournament(socket, socket.assigns.action, tournament_params)
  end

  defp save_tournament(socket, :edit, tournament_params) do
    case Tournaments.update_tournament(socket.assigns.tournament, tournament_params) do
      {:ok, tournament} ->
        notify_parent({:saved, tournament})

        {:noreply,
         socket
         |> put_flash(:info, "Tournament updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_tournament(socket, :new, tournament_params) do
    tournament_params =
      Map.put(tournament_params, "user_id", socket.assigns.current_user.id)

    case Tournaments.create_tournament(tournament_params) do
      {:ok, tournament} ->
        notify_parent({:saved, tournament})

        case Participants.create_x_participants(
               tournament.id,
               tournament_params["participant_count"]
             ) do
          {:ok, _} ->
            {:noreply,
             socket
             |> put_flash(:info, "Tournament created successfully")
             |> push_navigate(to: "/tournaments/#{tournament.id}")}

          _ ->
            {:noreply, socket}
        end

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp get_subformat_options(subformat) do
    case to_string(subformat) do
      "edh" ->
        [
          {"Bubble Rounds (Pods are determined by last round standings)", :bubble_rounds},
          {"Swiss Rounds", :swiss}
        ]

      "single" ->
        [
          {"Swiss Rounds", :swiss}
        ]

      _ ->
        [{"None", :none}]
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
