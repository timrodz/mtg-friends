defmodule MtgFriendsWeb.TournamentLive.Round do
  use MtgFriendsWeb, :live_view

  alias MtgFriendsWeb.UserAuth
  alias MtgFriends.Rounds

  on_mount {MtgFriendsWeb.UserAuth, :mount_current_user}

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp generate_socket(socket, tournament_id, round_number) do
    round = Rounds.get_round_from_round_number_str!(tournament_id, round_number)

    pairing_groups =
      Enum.group_by(round.pairings, fn pairing -> pairing.number end)
      |> Enum.map(fn {index, pairings} ->
        {index,
         %{
           pairings: pairings,
           active: Enum.any?(pairings, fn p -> p.active == true end),
           pairing_winner: Enum.find(pairings, fn p -> p.winner end)
         }}
      end)

    forms =
      pairing_groups
      |> Enum.map(fn {index, pairing_groups} ->
        {index,
         to_form(%{
           "pairing_number" => index,
           "winner_id" => "",
           "participants" =>
             Enum.map(
               Enum.sort_by(pairing_groups.pairings, fn p -> p.points end, :desc),
               fn pairing ->
                 %{
                   id: pairing.participant.id,
                   points: pairing.points || 0,
                   name: pairing.participant.name
                 }
               end
             )
         })}
      end)

    socket
    |> assign(
      round_id: round.id,
      round_number: round.number,
      is_round_active: round.active,
      has_pairings: length(round.pairings) > 0,
      tournament_id: round.tournament.id,
      tournament_name: round.tournament.name,
      tournament_rounds: round.tournament.rounds,
      participants: round.tournament.participants,
      pairing_groups: pairing_groups,
      num_pairings: round(Float.ceil(length(round.tournament.participants) / 4)),
      forms: forms
    )
    |> UserAuth.assign_current_user_owner(
      socket.assigns.current_user,
      round.tournament
    )
  end

  defp apply_action(socket, :index, %{
         "tournament_id" => tournament_id,
         "round_number" => round_number
       }) do
    socket
    |> assign(:page_title, "Round Pairings")
    |> assign(:selected_page_number, nil)
    |> generate_socket(tournament_id, round_number)
  end

  defp apply_action(socket, :edit, %{
         "tournament_id" => tournament_id,
         "round_number" => round_number,
         "pairing_number" => pairing_number_str
       }) do
    {pairing_number, ""} = Integer.parse(pairing_number_str)

    socket
    |> assign(:page_title, "Update pod results")
    |> assign(:selected_page_number, pairing_number)
    |> generate_socket(tournament_id, round_number)
  end

  @impl true
  def handle_event("finish-round", _, socket) do
    %{round_number: round_number, round_id: round_id} = socket.assigns

    round = Rounds.get_round!(round_id)

    case Rounds.update_round(round, %{active: false}) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Round #{round_number + 1} finished successfully")
         |> reload_page()}

      {:error, %Ecto.Changeset{} = _} ->
        {:noreply,
         put_flash(socket, :error, "Something wrong happened when finishing this round")}
    end
  end

  defp reload_page(socket) do
    socket
    |> push_navigate(
      to:
        ~p"/tournaments/#{socket.assigns.tournament_id}/rounds/#{socket.assigns.round_number + 1}"
    )
  end
end
