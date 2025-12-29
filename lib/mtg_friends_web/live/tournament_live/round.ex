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
      pairing_groups: pairing_groups,
      page_title:
        case action do
          :index ->
            "#{round.tournament.name} / Round #{round.number + 1}"

          :edit ->
            "#{round.tournament.name} / Round #{round.number + 1} / Pod ##{socket.assigns.selected_pairing_number}"
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
