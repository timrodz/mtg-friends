defmodule MtgFriendsWeb.TournamentLive.TournamentEndFormComponent do
  alias MtgFriends.Participants
  alias MtgFriends.Tournaments
  alias MtgFriends.Rounds
  use MtgFriendsWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>Use this form below to select the winner of this tournament</:subtitle>
      </.header>

      <br />

      <.simple_form for={@form} id={"edit-pairing-#{@id}"} phx-target={@myself} phx-submit="save">
        <.input
          :if={@tournament.is_top_cut_4}
          label="Choose the name of the participant who won"
          name="participant_id"
          type="select"
          value="-1"
          options={
            Enum.map(@form.params["participants"], fn p -> {String.capitalize(p.name), p.id} end)
          }
        />
        <br />
        <:actions>
          <.button phx-disable-with="Saving..." data-confirm="Are you sure?">
            Submit changes and finish tournament
          </.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(assigns, socket) do
    {
      :ok,
      socket
      |> assign(assigns)
      |> assign_form(%{"participants" => assigns.tournament.participants})
    }
  end

  @impl true
  def handle_event(
        "save",
        params,
        socket
      ) do
    %{"participant_id" => participant_id_str} = params
    {participant_id, ""} = Integer.parse(participant_id_str)
    tournament = socket.assigns.tournament

    participant =
      tournament.participants
      |> IO.inspect(label: "participants")
      |> Enum.find(fn p -> p.id == participant_id end)

    with {:ok, _} <-
           Participants.update_participant(participant, %{"is_tournament_winner" => true}),
         {:ok, _} <- Tournaments.update_tournament(tournament, %{"status" => :finished}) do
      {:noreply, socket |> put_flash(:info, "This tournament is now finished!") |> reload_page()}
    else
      _ ->
        nil
        {:noreply, socket |> put_flash(:error, "Error updating pairing")}
    end
  end

  defp assign_form(socket, changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp reload_page(socket) do
    socket |> push_navigate(to: ~p"/tournaments/#{socket.assigns.tournament.id}", replace: true)
  end
end
