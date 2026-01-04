defmodule MtgFriendsWeb.TournamentLive.Round do
  use MtgFriendsWeb, :live_view

  alias MtgFriendsWeb.UserAuth
  alias MtgFriends.Rounds
  alias MtgFriends.Utils.Date

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
         "pairing_id" => pairing_id_str
       }) do
    {pairing_id, ""} = Integer.parse(pairing_id_str)

    socket
    |> assign(:selected_pairing_id, pairing_id)
    |> generate_socket(tournament_id, round_number, :edit)
  end

  defp generate_socket(socket, tournament_id, round_number, action) do
    round = Rounds.get_round_from_round_number_str!(tournament_id, round_number)
    # Ensure pairings are loaded with participants
    round = MtgFriends.Repo.preload(round, pairings: [pairing_participants: :participant])

    # Map pairings to a structure easier for the template
    # We can use the list index as "Table Number" for display since we removed `number` column
    pairings_with_index = Enum.with_index(round.pairings, 1)

    forms =
      pairings_with_index
      |> Enum.map(fn {pairing, index} ->
        {pairing.id,
         to_form(%{
           "pairing_id" => pairing.id,
           "table_number" => index,
           "winner_id" => pairing.winner_id,
           "participants" =>
             Enum.map(
               Enum.sort_by(pairing.pairing_participants, fn pp -> pp.points end, :desc),
               fn pp ->
                 %{
                   id: pp.participant.id,
                   points: pp.points || 0,
                   name: pp.participant.name
                 }
               end
             )
         })}
      end)
      |> Map.new()

    round_finish_time =
      case round.started_at do
        nil -> nil
        _ -> NaiveDateTime.add(round.started_at, round.tournament.round_length_minutes, :minute)
      end

    with timer_reference <- Map.get(socket.assigns, :timer_reference),
         false <- is_nil(timer_reference) do
      {:ok, ref} = timer_reference
      :timer.cancel(ref)
    end

    socket
    |> assign(
      timer_reference:
        if(round.status == :active and connected?(socket),
          do: :timer.send_interval(1000, self(), :tick),
          else: nil
        ),
      round_id: round.id,
      round_started_at: round.started_at,
      round_number: round.number,
      round_status: round.status,
      round_finish_time: round_finish_time,
      round_countdown_timer: get_countdown_timer(round_finish_time),
      tournament_id: round.tournament.id,
      tournament_name: round.tournament.name,
      tournament_rounds: round.tournament.rounds,
      participants: round.tournament.participants,
      # passing list of {pairing, index}
      pairings: pairings_with_index,
      page_title:
        case action do
          :index ->
            "#{round.tournament.name} / Round #{round.number + 1}"

          :edit ->
            "#{round.tournament.name} / Round #{round.number + 1} / Edit Pairing"
        end,
      # num_pairings logic was just for display, now we have explicit pairings
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
       round_countdown_timer: get_countdown_timer(socket.assigns.round_finish_time)
     )}
  end

  @impl true
  def handle_event("start-round", _, socket) do
    %{round_id: round_id} = socket.assigns
    round = Rounds.get_round!(round_id)
    Rounds.update_round(round, %{status: :active, started_at: NaiveDateTime.utc_now()})

    {:noreply,
     socket
     |> put_flash(:info, "This round has now begun!")
     |> reload_page}
  end

  @impl true
  def handle_event("finish-round", _, socket) do
    %{round_id: round_id} = socket.assigns
    round = Rounds.get_round!(round_id)
    Rounds.update_round(round, %{status: :finished})

    {:noreply,
     socket
     |> put_flash(:info, "This round has now begun!")
     |> reload_page}
  end

  defp get_countdown_timer(round_end_time) do
    case round_end_time do
      nil ->
        ""

      _ ->
        time_diff = NaiveDateTime.diff(round_end_time, NaiveDateTime.utc_now())

        if time_diff > 0 do
          {time_diff, Date.to_hh_mm_ss(time_diff)}
        else
          {0, "00:00"}
        end
    end
  end

  defp reload_page(socket) do
    %{tournament_id: tournament_id, round_number: round_number} = socket.assigns

    socket
    |> push_navigate(
      to: ~p"/tournaments/#{tournament_id}/rounds/#{round_number + 1}",
      replace: true
    )
  end
end
