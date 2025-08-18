# Rounds System Documentation

## Overview

The rounds system in MTG Friends manages the temporal structure of tournaments, dividing tournament play into discrete time periods with their own pairings, scoring, and status tracking. Each round represents a complete cycle of games played simultaneously across all participants.

## Architecture

### Core Components

The rounds system is organized around several interconnected modules:

- **Rounds Context** (`lib/mtg_friends/rounds.ex`) - CRUD operations and business logic
- **Round Schema** (`lib/mtg_friends/rounds/round.ex`) - Database schema and validation
- **Integration with Tournaments** - Rounds belong to tournaments and contain pairings
- **LiveView Integration** - Real-time round management through web interface

### Database Schema

```elixir
schema "rounds" do
  field :status, Ecto.Enum, values: [:inactive, :active, :finished], default: :inactive
  field :number, :integer              # 0-indexed round number (0, 1, 2, ...)
  field :started_at, :naive_datetime   # When round officially started

  belongs_to :tournament, MtgFriends.Tournaments.Tournament
  has_many :pairings, MtgFriends.Pairings.Pairing

  timestamps()
end
```

**Key Relationships:**

- Each round belongs to exactly one tournament
- Each round contains multiple pairings (player groupings)
- Rounds are numbered sequentially starting from 0
- Status tracks the lifecycle of each round

## Round Lifecycle

### 1. Round Creation

**Primary Creation Function:**

```elixir
def create_round_for_tournament(tournament_id, tournament_rounds) do
  %Round{}
  |> Round.changeset(%{
    tournament_id: tournament_id,
    number: tournament_rounds      # 0-indexed (0, 1, 2, ...)
  })
  |> Repo.insert()
end
```

**Creation Context:**

- **Tournament Association**: Round immediately linked to parent tournament
- **Sequential Numbering**: Round numbers assigned sequentially (0, 1, 2, ...)
- **Default Status**: Rounds start in `:inactive` status
- **Timestamp Tracking**: Automatic `inserted_at` and `updated_at` timestamps

**Typical Creation Flow:**

```elixir
# During tournament progression
for round_number <- 0..(tournament.round_count - 1) do
  {:ok, round} = Rounds.create_round_for_tournament(tournament.id, round_number)

  # Generate pairings for this round
  tournament = Tournaments.get_tournament!(tournament.id)
  round = Rounds.get_round!(round.id, true)  # Preload associations

  {:ok, _pairings} = PairingEngine.create_pairings(tournament, round)
end
```

### 2. Round Status Management

**Status Progression:**

```
:inactive → :active → :finished
```

**Status Meanings:**

- **`:inactive`** - Round created but not yet started, pairings may be generated
- **`:active`** - Round currently being played, scores being collected
- **`:finished`** - Round completed, all scores recorded, ready for next round

**Status Transitions:**

```elixir
# Start a round
{:ok, round} = Rounds.update_round(round, %{
  status: :active,
  started_at: NaiveDateTime.local_now()
})

# Finish a round (typically after all scores collected)
{:ok, round} = Rounds.update_round(round, %{status: :finished})
```

### 3. Round Data Retrieval

**Basic Retrieval:**

```elixir
# Simple round lookup
round = Rounds.get_round!(round_id)

# Round with all associations preloaded
round = Rounds.get_round!(round_id, true)
# Includes: tournament with participants, pairings with participants
```

**Tournament-Context Retrieval:**

```elixir
# Get round by tournament and round number
round = Rounds.get_round_by_tournament_and_round_number!(
  tournament_id,
  round_number,
  preload_all: true
)

# Get round from string-based round number (UI integration)
round = Rounds.get_round_from_round_number_str!(tournament_id, "2")
# Converts "2" to 1 (adjusts for 1-indexed display vs 0-indexed storage)
```

## Round Management Features

### Preloading Strategies

**Selective Preloading:**

```elixir
def get_round!(id, preload_all \\ false) do
  if preload_all do
    Repo.get!(Round, id)
    |> Repo.preload(tournament: [:participants], pairings: [:participant])
  else
    Repo.get!(Round, id)
  end
end
```

**Benefits:**

- **Performance Control**: Only load associated data when needed
- **Memory Efficiency**: Avoid loading unnecessary associations
- **Query Optimization**: Single query with joins vs multiple queries

### Tournament Integration

**Round-Tournament Relationship:**

```elixir
def get_round_by_tournament_and_round_number!(tournament_id, round_number, preload_all \\ false) do
  base_query = Repo.get_by!(Round, tournament_id: tournament_id, number: round_number)

  if preload_all do
    base_query
    |> Repo.preload(tournament: [:participants, rounds: [:pairings]], pairings: [:participant])
  else
    base_query
    |> Repo.preload(pairings: [:participant])
  end
end
```

**Deep Association Loading:**

- **Tournament Context**: Loads parent tournament with all participants
- **Sibling Rounds**: Includes other rounds for comparison and scoring
- **Nested Pairings**: Each round's pairings with participant details

### Display Number Conversion

**UI Integration:**

```elixir
def get_round_from_round_number_str!(tournament_id, number_str) do
  {number, ""} = Integer.parse(number_str)

  # Convert from 1-indexed display to 0-indexed storage
  Repo.get_by!(Round, tournament_id: tournament_id, number: number - 1)
  |> Repo.preload(tournament: [:participants, rounds: :pairings], pairings: [:participant])
end
```

**Conversion Logic:**

- **Database Storage**: 0-indexed (0, 1, 2, 3 for 4-round tournament)
- **User Display**: 1-indexed (Round 1, Round 2, Round 3, Round 4)
- **Automatic Conversion**: Handles display-to-storage conversion seamlessly

## Round State Management

### Active Round Detection

**Current Round Logic:**

```elixir
# In tournament LiveView
assign(:is_current_round_active?,
  with len <- length(tournament.rounds), true <- len > 0 do
    round = Enum.at(tournament.rounds, len - 1)  # Last round
    round.status != :finished
  else
    _ -> false
  end
)
```

**Usage Patterns:**

- **UI State**: Controls whether round management UI is shown
- **Button States**: Enables/disables "Start Round", "End Round" buttons
- **Validation**: Prevents creating new rounds while current round active

### Round Progression Logic

**Sequential Round Creation:**

```elixir
def start_next_round(tournament) do
  current_round_count = length(tournament.rounds)

  if current_round_count < tournament.round_count do
    # Create next round
    {:ok, round} = create_round_for_tournament(tournament.id, current_round_count)

    # Generate pairings
    tournament = reload_tournament_with_associations(tournament.id)
    round = get_round!(round.id, true)

    {:ok, _pairings} = PairingEngine.create_pairings(tournament, round)

    # Activate the round
    update_round(round, %{status: :active, started_at: NaiveDateTime.local_now()})
  else
    {:error, :tournament_complete}
  end
end
```

### Time Tracking

**Round Timing:**

```elixir
# Record when round starts
{:ok, round} = Rounds.update_round(round, %{
  status: :active,
  started_at: NaiveDateTime.local_now()
})

# Calculate round duration (in views/utilities)
def round_duration(round) do
  case round.started_at do
    nil -> nil
    start_time ->
      end_time = round.updated_at  # When status changed to :finished
      NaiveDateTime.diff(end_time, start_time, :second)
  end
end
```

## Integration with Other Systems

### Pairing System Integration

**Round-Pairing Relationship:**

- Each round contains multiple pairings
- Pairings are created immediately after round creation
- Round status affects pairing behavior (scoring only when active)

```elixir
# Typical round-pairing workflow
{:ok, round} = Rounds.create_round_for_tournament(tournament.id, round_number)
tournament = Tournaments.get_tournament!(tournament.id)
round = Rounds.get_round!(round.id, true)

# Generate pairings using sophisticated algorithms
{:ok, %{insert_all: {pairing_count, _}}} = PairingEngine.create_pairings(tournament, round)

# Activate round for scoring
{:ok, round} = Rounds.update_round(round, %{status: :active})
```

### Tournament System Integration

**Round Limits:**

```elixir
# Tournament schema defines round limits
field :round_count, :integer, default: 4

# Round creation respects tournament limits
def can_create_round?(tournament) do
  length(tournament.rounds) < tournament.round_count
end
```

**Special Round Logic:**

```elixir
# Last round detection for top cut
is_last_round? = tournament.round_count == round.number + 1
is_top_cut_4? = is_last_round? && tournament.is_top_cut_4

if is_top_cut_4? do
  create_top_cut_pairings(tournament, round, num_pairings)
else
  create_regular_pairings(tournament, round, active_participants, num_pairings)
end
```

### Scoring System Integration

**Score Collection Context:**

```elixir
# Rounds provide context for score updates
def update_pairings(tournament_id, round_id, form_params) do
  # Find all pairings for this specific round
  participant_scores = extract_scores_from_form(form_params)

  multi = Enum.reduce(participant_scores, Ecto.Multi.new(), fn params, multi ->
    pairing = Pairings.get_pairing!(tournament_id, round_id, participant_id)
    # ... update pairing with scores
  end)

  Repo.transaction(multi)
end
```

## LiveView Integration

### Real-time Round Management

**Round Status Updates:**

```elixir
# In TournamentLive.Show
def handle_event("start_round", %{"round_id" => round_id}, socket) do
  round = Rounds.get_round!(round_id)

  case Rounds.update_round(round, %{status: :active, started_at: NaiveDateTime.local_now()}) do
    {:ok, _round} ->
      # Broadcast update to all connected clients
      {:noreply, socket |> put_flash(:info, "Round started!") |> push_redirect(...)}
    {:error, changeset} ->
      {:noreply, socket |> put_flash(:error, "Failed to start round")}
  end
end
```

**Dynamic UI Updates:**

- Round status changes trigger UI reloads
- Button states update based on round status
- Timer displays track active round duration

### Form Integration

**Round Management Forms:**

```elixir
# Round editing component
defmodule MtgFriendsWeb.TournamentLive.RoundEditPairingFormComponent do
  def update(%{round: round}, socket) do
    changeset = Rounds.change_round(round)

    {:ok,
     socket
     |> assign(:round, round)
     |> assign(:form, to_form(changeset))}
  end

  def handle_event("save", %{"round" => round_params}, socket) do
    case Rounds.update_round(socket.assigns.round, round_params) do
      {:ok, round} ->
        notify_parent({:saved, round})
        {:noreply, socket |> put_flash(:info, "Round updated successfully")}
      {:error, changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end
end
```

## Error Handling and Edge Cases

### Validation Errors

**Required Fields:**

- `tournament_id` - Must reference valid tournament
- `number` - Must be non-negative integer
- `status` - Must be valid enum value

**Business Logic Validation:**

```elixir
def validate_round_creation(tournament, round_number) do
  cond do
    length(tournament.rounds) >= tournament.round_count ->
      {:error, "Tournament round limit reached"}

    Enum.any?(tournament.rounds, fn r -> r.number == round_number end) ->
      {:error, "Round number already exists"}

    round_number < 0 ->
      {:error, "Round number cannot be negative"}

    true ->
      :ok
  end
end
```

### State Management Issues

**Invalid Status Transitions:**

```elixir
def valid_status_transition?(current_status, new_status) do
  case {current_status, new_status} do
    {:inactive, :active} -> true
    {:active, :finished} -> true
    {:inactive, :finished} -> true  # Allow skip to finished
    _ -> false
  end
end
```

**Concurrent Round Management:**

- Database constraints prevent duplicate round numbers
- Transaction isolation prevents race conditions
- Optimistic locking through `updated_at` timestamps

### Data Integrity

**Orphaned Round Prevention:**

```elixir
# Foreign key constraints in migration
add :tournament_id, references(:tournaments, on_delete: :delete_all), null: false
```

**Pairing Consistency:**

- Rounds cannot be deleted if they have pairings
- Round status changes validated against pairing states
- Cascade deletes ensure cleanup when tournaments removed

## Performance Considerations

### Query Optimization

**Strategic Preloading:**

```elixir
# Expensive but comprehensive
tournament = Repo.get!(Tournament, id)
|> Repo.preload([
  participants: [],
  rounds: [pairings: [:participant]]
])

# Selective loading for specific needs
round = Repo.get!(Round, id)
|> Repo.preload([pairings: [:participant]])
```

**Batch Operations:**

```elixir
# Create multiple rounds efficiently
rounds_data = for round_num <- 0..3, do: %{
  tournament_id: tournament.id,
  number: round_num,
  status: :inactive,
  inserted_at: now,
  updated_at: now
}

Repo.insert_all(Round, rounds_data)
```

### Memory Management

**Lazy Loading:**

- Only preload associations when specifically needed
- Use streaming for large tournament histories
- Implement pagination for round listings

**Cache Considerations:**

- Round status cached in tournament LiveView state
- Pairing data cached until round completion
- Score calculations cached for performance

## Usage Patterns

### Standard Round Flow

```elixir
# 1. Create tournament with round limit
{:ok, tournament} = Tournaments.create_tournament(%{
  round_count: 3,
  # ... other attributes
})

# 2. For each round in tournament
for round_number <- 0..(tournament.round_count - 1) do
  # Create round
  {:ok, round} = Rounds.create_round_for_tournament(tournament.id, round_number)

  # Generate pairings
  tournament = Tournaments.get_tournament!(tournament.id)
  round = Rounds.get_round!(round.id, true)
  {:ok, _pairings} = PairingEngine.create_pairings(tournament, round)

  # Start round
  {:ok, round} = Rounds.update_round(round, %{
    status: :active,
    started_at: NaiveDateTime.local_now()
  })

  # ... collect scores from games ...

  # Finish round
  {:ok, round} = Rounds.update_round(round, %{status: :finished})
end

# 3. Tournament complete
Tournaments.update_tournament(tournament, %{status: :finished})
```

### Round Analysis

```elixir
# Analyze round completion times
def analyze_round_durations(tournament) do
  tournament.rounds
  |> Enum.map(fn round ->
    duration = calculate_round_duration(round)
    %{
      round_number: round.number + 1,  # Display as 1-indexed
      duration_minutes: duration / 60,
      started_at: round.started_at,
      status: round.status
    }
  end)
end
```

The rounds system provides the temporal framework that organizes tournament play into manageable segments while maintaining data integrity and supporting real-time tournament management through sophisticated state tracking and LiveView integration.
