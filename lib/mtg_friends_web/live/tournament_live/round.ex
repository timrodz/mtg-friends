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

  defp apply_action(socket, :index, %{
         "tournament_id" => tournament_id,
         "round_number" => round_number
       }) do
    socket
    |> assign(:page_title, "Round Pairings")
    |> assign(:selected_pairing_number, nil)
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
    |> assign(:selected_pairing_number, pairing_number)
    |> generate_socket(tournament_id, round_number)
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
      |> Enum.map(fn {index, pairing_group} ->
        {index,
         to_form(%{
           "pairing_number" => index,
           "winner_id" => "",
           "participants" =>
             Enum.map(
               Enum.sort_by(pairing_group.pairings, fn pairings -> pairings.points end, :desc),
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

    round_finish_time = NaiveDateTime.add(round.inserted_at, 60, :minute)

    with timer_reference <- Map.get(socket.assigns, :timer_reference),
         false <- is_nil(timer_reference) do
      {:ok, ref} = timer_reference
      :timer.cancel(ref)
    else
      _ -> nil
    end

    socket
    |> assign(
      timer_reference:
        if(round.active and connected?(socket),
          do: :timer.send_interval(1000, self(), :tick),
          else: nil
        ),
      round_id: round.id,
      round_number: round.number,
      is_round_active: round.active,
      round_finish_time: round_finish_time,
      round_finish_time_countdown: time_diff(if round.active, do: round_finish_time, else: 0),
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

  def handle_info(:tick, socket) do
    {:noreply,
     assign(socket,
       round_finish_time_countdown: time_diff(socket.assigns.round_finish_time)
     )}
  end

  defp time_diff(end_time) do
    case end_time do
      0 ->
        "00:00"

      _ ->
        now = NaiveDateTime.utc_now()
        seconds = NaiveDateTime.diff(end_time, now)

        if seconds > 0 do
          Seconds.to_hh_mm_ss(seconds)
        else
          "00:00"
        end
    end
  end
end
