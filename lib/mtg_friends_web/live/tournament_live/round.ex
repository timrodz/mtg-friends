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
    |> assign(:selected_pairing_number, nil)
    |> generate_socket(tournament_id, round_number, :index)
  end

  defp apply_action(socket, :edit, %{
         "tournament_id" => tournament_id,
         "round_number" => round_number,
         "pairing_number" => pairing_number_str
       }) do
    {pairing_number, ""} = Integer.parse(pairing_number_str)

    socket
    |> assign(:selected_pairing_number, pairing_number)
    |> generate_socket(tournament_id, round_number, :edit)
  end

  defp generate_socket(socket, tournament_id, round_number, action) do
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

    round_finish_time =
      NaiveDateTime.add(round.inserted_at, round.tournament.round_length_minutes, :minute)

    with timer_reference <- Map.get(socket.assigns, :timer_reference),
         false <- is_nil(timer_reference) do
      {:ok, ref} = timer_reference
      :timer.cancel(ref)
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
      round_countdown_timer: render_countdown_timer(round_finish_time),
      has_pairings?: length(round.pairings) > 0,
      tournament_id: round.tournament.id,
      tournament_name: round.tournament.name,
      tournament_rounds: round.tournament.rounds,
      participants: round.tournament.participants,
      pairing_groups: pairing_groups,
      page_title:
        case action do
          :index ->
            "Round #{round.number + 1} - Tournament #{round.tournament.name}"

          :edit ->
            "Edit Pairing #{socket.assigns.selected_pairing_number} - Round #{round.number + 1} - Tournament #{round.tournament.name}"
        end,
      num_pairings: round(Float.ceil(length(round.tournament.participants) / 4)),
      forms: forms
    )
    |> UserAuth.assign_current_user_owner(
      socket.assigns.current_user,
      round.tournament
    )
  end

  @impl true
  def handle_info(:tick, socket) do
    {:noreply,
     assign(socket,
       round_countdown_timer: render_countdown_timer(socket.assigns.round_finish_time)
     )}
  end

  defp render_countdown_timer(round_end_time) do
    time_diff = NaiveDateTime.diff(round_end_time, NaiveDateTime.utc_now())

    {diff_seconds, rendered_time} =
      if time_diff > 0,
        do: {time_diff, Seconds.to_hh_mm_ss(time_diff)},
        else: {0, "00:00"}

    raw("""
    <div id="round_countdown_timer" class="#{cond do
      diff_seconds > 60 * 5 and diff_seconds <= 60 * 10 -> "rounded-lg bg-yellow-200"
      diff_seconds >= 60 and diff_seconds <= 60 * 5 -> "rounded-lg bg-orange-200"
      diff_seconds > 0 and diff_seconds < 60 -> "animate-bounce rounded-lg bg-red-200"
      diff_seconds <= 0 -> "rounded-lg bg-red-200"
      true -> ""
    end}"
    >
      Round time: <span class="font-mono">#{rendered_time}</span>
    </div>
    """)
  end
end
