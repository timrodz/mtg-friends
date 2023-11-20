defmodule MtgFriendsWeb.TournamentLive.Round do
  use MtgFriendsWeb, :live_view

  alias MtgFriendsWeb.Live.TournamentLive.Utils
  alias MtgFriends.Participants
  alias MtgFriends.Pairings
  alias MtgFriends.Tournaments
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
      round_active: round.active,
      has_pairings: length(round.pairings) > 0
    )
    |> assign(
      tournament_id: round.tournament.id,
      tournament_name: round.tournament.name,
      tournament_rounds: round.tournament.rounds,
      participants: round.tournament.participants
    )
    |> assign(pairing_groups: pairing_groups, forms: forms)
    |> Utils.assign_current_user_tournament_owner(
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
      {:ok, round} ->
        {:noreply,
         socket
         |> put_flash(:info, "Round #{round_number + 1} finished successfully")
         |> reload_page()}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply,
         put_flash(socket, :error, "Something wrong happened when finishing this round")}
    end
  end

  @impl true
  def handle_event("create-pairings", _, socket) do
    %{
      tournament_id: tournament_id,
      round_id: round_id,
      round_number: round_number,
      participants: participants
    } =
      socket.assigns

    round_number |> IO.inspect(label: "round number")

    participant_pairings =
      case round_number do
        0 ->
          split_pairings_into_even_chunks(
            participants
            |> Enum.map(fn p -> %{id: p.id, name: p.name} end)
          )

        round ->
          sort_previous_round_results_by_points_and_shuffle_groups(socket, round)
          |> split_pairings_into_even_chunks()
      end

    participant_pairings
    |> Enum.with_index(fn pairing, index ->
      for participant <- pairing do
        Pairings.create_pairing(%{
          number: index,
          tournament_id: tournament_id,
          round_id: round_id,
          participant_id: participant.id
        })
      end
    end)

    {:noreply, socket |> put_flash(:info, "Pairings created successfully") |> reload_page()}
  end

  defp split_pairings_into_even_chunks(pairings) do
    total_pairings = length(pairings)

    with num_pairings <- round(Float.ceil(total_pairings / 4)),
         num_full_tables <- rem(total_pairings, num_pairings) do
      num_full_tables = if num_full_tables == 0, do: num_pairings, else: num_full_tables

      pairings_to_chunk_into_4 =
        (num_full_tables * 4) |> IO.inspect(label: "pairings to chunk into 4")

      chunks_4 =
        pairings
        |> Enum.slice(0..(pairings_to_chunk_into_4 - 1))
        |> Enum.chunk_every(4)
        |> IO.inspect(label: "chunks of 4")

      chunks_3 =
        pairings
        |> Enum.slice(pairings_to_chunk_into_4..total_pairings)
        |> Enum.chunk_every(3)
        |> IO.inspect(label: "chunks of 3")

      (chunks_4 ++ chunks_3) |> IO.inspect(label: "final chunks")
    else
      _ -> nil
    end
  end

  defp sort_previous_round_results_by_points_and_shuffle_groups(socket, current_round_number) do
    # current_round_number must be greater than 0
    %{tournament_id: tournament_id, participants: participants} = socket.assigns

    previous_round = Rounds.get_round!(tournament_id, current_round_number - 1)

    pairings =
      previous_round.pairings
      |> Enum.map(fn pairing ->
        %{
          id: pairing.participant_id,
          name: pairing.participant.name,
          points: pairing.points,
          winner: pairing.winner
        }
      end)
      |> Enum.group_by(fn p -> p.points end)
      |> Enum.reverse()
      |> Enum.flat_map(fn {index, participants} -> Enum.shuffle(participants) end)
  end

  defp reload_page(socket) do
    socket
    |> push_navigate(
      to:
        ~p"/tournaments/#{socket.assigns.tournament_id}/rounds/#{socket.assigns.round_number + 1}"
    )
  end
end
