# Pairing System Documentation

## Overview

The pairing system is the heart of tournament management in MTG Friends, responsible for matching players together in optimal groups for each round. It implements sophisticated algorithms to ensure fair play, minimize repeat opponents, and handle the unique requirements of different Magic: The Gathering formats.

## Architecture

### Core Components

The pairing system is structured across multiple modules with clear separation of concerns:

- **PairingEngine** (`lib/mtg_friends/pairing_engine.ex`) - Core pairing algorithms and logic
- **Pairings Context** (`lib/mtg_friends/pairings.ex`) - CRUD operations and business logic
- **Pairing Schema** (`lib/mtg_friends/pairings/pairing.ex`) - Database schema and validation
- **TournamentUtils** (`lib/mtg_friends/tournament_utils.ex`) - Integration layer and scoring

### Database Schema

```elixir
schema "pairings" do
  field :active, :boolean          # Whether pairing is currently active
  field :number, :integer          # Pairing/pod number within the round
  field :points, :integer          # Points earned by participant in this pairing
  field :winner, :boolean          # Whether this participant won their pairing

  belongs_to :tournament, MtgFriends.Tournaments.Tournament
  belongs_to :round, MtgFriends.Rounds.Round
  belongs_to :participant, MtgFriends.Participants.Participant
end
```

**Key Relationships:**

- Each pairing belongs to exactly one tournament, round, and participant
- Multiple pairings with the same `number` represent players in the same pod/match
- Points and winner status track individual performance within the group

## Pairing Algorithms

### Algorithm Selection

The system chooses pairing algorithms based on round number and tournament configuration:

```elixir
def create_pairings(tournament, round) do
  case round.number do
    0 -> create_first_round_pairings(tournament, round)  # Random
    _ ->
      case tournament.subformat do
        :swiss -> create_swiss_pairings(tournament, round)
        :bubble_rounds -> create_bubble_round_pairings(tournament, round)
      end
  end
end
```

### 1. First Round (Random) Pairings

**Purpose:** Establish initial random matchups for fair tournament start
**Algorithm:** Simple shuffle and partition

```elixir
def create_first_round_pairings(tournament, round) do
  active_participants = filter_active_participants(tournament.participants)
  num_pairings = calculate_num_pairings(length(active_participants), tournament.format)

  active_participants
  |> Enum.shuffle()  # Randomize order
  |> partition_participants_into_pairings(num_pairings, tournament.format)
  |> create_pairing_structs(tournament.id, round.id)
end
```

**Characteristics:**

- **No History**: Ignores any previous matchups
- **Pure Random**: Uses `Enum.shuffle()` for unpredictable ordering
- **Format Aware**: Respects EDH pod sizes vs Standard match sizes

### 2. Swiss Pairing System

**Purpose:** Minimize repeat opponents while maintaining competitive balance
**Algorithm:** Multi-retry optimization with opponent history tracking

```elixir
def create_swiss_pairings(tournament, num_pairings) do
  # Build matrix of who has played whom
  player_pairing_matrix = build_player_pairing_matrix(tournament, participant_ids)

  # Try optimal algorithm first
  case attempt_optimal_swiss_pairings(player_pairing_matrix, num_pairings, tournament.format) do
    {:ok, pairings} -> pairings
    {:fallback, _reason} ->
      # Fall back to retry-based algorithm
      generate_swiss_pairings_with_retries(12, num_pairings, player_pairing_matrix, [], tournament.format)
  end
end
```

#### Swiss Algorithm Components

**Opponent History Matrix:**

```elixir
def build_player_pairing_matrix(tournament, participant_ids) do
  mapped_rounds = extract_round_pairings(tournament.rounds)

  participant_ids
  |> Enum.map(fn id ->
    players_played_against = find_previous_opponents(mapped_rounds, id)
    players_not_played_with = calculate_unplayed_opponents(participant_ids, id, players_played_against)

    {id, players_played_against, players_not_played_with}
  end)
end
```

**Optimal Pairing Attempt:**

- Creates groups prioritizing players who haven't faced each other
- Uses available opponent lists to find compatible pairings
- Falls back to retry system if optimal solution impossible

**Retry-Based Fallback:**

```elixir
def generate_swiss_pairings_with_retries(retries_left, num_pairings, player_matrix, best_round, tournament_format) do
  shuffled_matrix = Enum.shuffle(player_matrix)
  pairings = partition_participants_into_pairings(shuffled_matrix, num_pairings, tournament_format)

  # Evaluate quality - count repeat opponents
  pairing_results = evaluate_pairing_quality(pairings)
  total_repeated = sum_repeated_opponents(pairing_results)

  # Keep best result across all attempts
  new_best = if total_repeated < best_score, do: pairing_results, else: best_round

  # Recursively try remaining attempts
  generate_swiss_pairings_with_retries(retries_left - 1, ...)
end
```

**Quality Evaluation:**

- Counts how many previous opponents are in each pod/match
- Minimizes total "repeated opponent" score across all pairings
- Balances randomness with opponent avoidance

### 3. Bubble Rounds Pairing

**Purpose:** Group players of similar performance levels together
**Algorithm:** Score-based grouping with shuffling within tiers

```elixir
def create_bubble_round_pairings(tournament_id, current_round_number) do
  previous_round = get_previous_round_results(tournament_id, current_round_number - 1)

  previous_round.pairings
  |> extract_participant_scores()
  |> Enum.group_by(fn p -> p.points end)  # Group by score
  |> Enum.sort(:desc)                     # Best scores first
  |> Enum.flat_map(fn {_, participants} ->
      Enum.shuffle(participants)          # Randomize within score tier
     end)
end
```

**Characteristics:**

- **Performance Tiers**: Groups players with same point totals
- **Descending Order**: Higher-scoring players paired first
- **Within-Tier Randomness**: Shuffles players of equal performance
- **Competitive Balance**: Creates more evenly matched pods/games

### 4. Top Cut Pairings

**Purpose:** Create elimination bracket from top performers
**Algorithm:** Score-based selection of top 4 players

**Characteristics:**

- **Merit-Based**: Only top-scoring players advance
- **Final Round**: Typically used in last tournament round
- **Single Pairing**: All finalists in one decisive game/match
- **Winner-Take-All**: Determines tournament champion

## Format-Specific Logic

### EDH/Commander Format

**Pod Size Management:**

```elixir
def partition_edh_participants(participants, participant_count, num_pairings) do
  corrected_num_complete_pairings = calculate_complete_pairings(participant_count, num_pairings)

  case corrected_num_complete_pairings do
    0 ->
      # All 3-player pods
      participants |> Enum.chunk_every(3)
    _ ->
      # Mix of 4-player and 3-player pods
      complete_4_player_pods ++ remaining_3_player_pods
  end
end
```

**Special Cases Handled:**

- **6 Players**: 2 pods of 3 (avoids awkward 1 pod of 4 + 1 pod of 2)
- **9 Players**: 3 pods of 3 (optimal distribution)
- **10 Players**: 2 pods of 4 + 1 pod of 3 (converted from 2 pods of 4 + 1 pod of 2)
- **Odd Numbers**: Intelligently balances pod sizes for best gameplay

**Pod Size Priority:**

1. **4-player pods** - Optimal EDH experience
2. **3-player pods** - Acceptable alternative
3. **2-player pods** - Avoided (poor EDH experience)

### Standard Format

**Match Creation:**

```elixir
def partition_standard_participants(participants, _participant_count, _num_pairings) do
  participants |> Enum.chunk_every(2)  # Simple 2-player matches
end
```

**Characteristics:**

- **Fixed Size**: Always 2 players per match
- **Bye Handling**: Odd numbers result in one player receiving a bye
- **Straightforward**: No complex pod size optimization needed

## Pairing Data Management

### Creating Pairings

**Bulk Creation Process:**

```elixir
def create_multiple_pairings(participant_pairings) do
  now = NaiveDateTime.local_now()

  new_pairings =
    participant_pairings
    |> Enum.map(fn p ->
        p
        |> Map.put(:inserted_at, now)
        |> Map.put(:updated_at, now)
       end)

  Ecto.Multi.new()
  |> Ecto.Multi.insert_all(:insert_all, Pairing, new_pairings)
  |> Repo.transaction()
end
```

**Benefits:**

- **Atomic Operations**: All pairings created in single transaction
- **Performance**: Bulk insert much faster than individual creates
- **Consistency**: Ensures all pairings have same timestamp
- **Error Recovery**: Transaction rollback if any pairing fails

### Updating Scores

**Score Collection Process:**

```elixir
def update_pairings(tournament_id, round_id, form_params) do
  participant_scores = extract_scores_from_form(form_params)

  # Determine winner (highest score, handle ties)
  highest_score_participant = find_winner(participant_scores)

  # Update all pairings in transaction
  multi = Enum.reduce(participant_scores, Ecto.Multi.new(), fn params, multi ->
    pairing = get_pairing!(tournament_id, round_id, participant_id)
    changeset = change_pairing(pairing, add_winner_flag(params, highest_score_participant))

    Ecto.Multi.update(multi, "update_pairing_#{pairing.id}", changeset)
  end)

  Repo.transaction(multi)
end
```

**Winner Determination:**

- **Highest Score Wins**: Player with most points wins the pod/match
- **Tie Handling**: No winner declared if multiple players tie for highest
- **Group Scoring**: All participants get points, only one gets winner flag

## Advanced Features

### Dropped Player Handling

**Filtering Logic:**

```elixir
def filter_active_participants(participants) do
  Enum.filter(participants, fn p -> not p.is_dropped end)
end
```

**Impact:**

- **Pairing Exclusion**: Dropped players not included in new pairings
- **Historical Data**: Previous pairings and scores preserved
- **Dynamic Adjustment**: Pod/match sizes adjust automatically
- **Re-entry**: Players can be un-dropped if rules allow

### Configuration Constants

**Pairing Engine Settings:**

```elixir
@max_swiss_retries 12                    # Maximum optimization attempts
@edh_players_per_pod 4                   # Preferred EDH pod size
@edh_min_players_per_pod 3               # Minimum acceptable EDH pod size
@standard_players_per_pairing 2          # Standard match size
```

**Tuning Considerations:**

- **Retry Count**: More retries = better opponent avoidance but slower performance
- **Pod Sizes**: Balance gameplay quality vs practical constraints
- **Format Flexibility**: Easy to add new formats by adjusting constants

### Performance Optimization

**Matrix Building Optimization:**

- **Ordsets Usage**: Efficient set operations for opponent calculations
- **Precomputed Relationships**: Build opponent matrix once per round
- **Lazy Evaluation**: Only compute expensive operations when needed

**Pairing Quality Assessment:**

```elixir
def evaluate_pairing_quality(pairings) do
  pairings
  |> Enum.map(fn pairing ->
    repeated_opponents = count_repeated_opponents_in_pairing(pairing)
    %{total_repeated_opponents: repeated_opponents, pairing: pairing}
  end)
end
```

## Error Handling and Edge Cases

### Insufficient Players

- **Minimum Thresholds**: EDH requires 3+ players, Standard 2+
- **Graceful Degradation**: Creates smaller pods/matches when possible
- **User Feedback**: Clear error messages for impossible pairings

### Algorithm Failures

- **Swiss Fallbacks**: Multiple retry strategies if optimal pairing fails
- **Logging**: Detailed logs for debugging pairing issues
- **Recovery**: Always produces valid pairings even if not optimal

### Data Integrity

- **Transaction Safety**: All pairing operations wrapped in database transactions
- **Validation**: Schema validation ensures required fields present
- **Referential Integrity**: Foreign key constraints prevent orphaned pairings

## Usage Patterns

### Standard Pairing Flow

```elixir
# 1. Create round
{:ok, round} = Rounds.create_round_for_tournament(tournament.id, round_number)

# 2. Generate pairings
tournament = Tournaments.get_tournament!(tournament.id)  # Reload with associations
round = Rounds.get_round!(round.id, true)               # Preload associations

{:ok, %{insert_all: {pairing_count, _}}} = PairingEngine.create_pairings(tournament, round)

# 3. Collect and update scores
scores = collect_scores_from_games()
{:ok, _} = Pairings.update_pairings(tournament.id, round.id, scores)
```

### Custom Pairing Requirements

```elixir
# Override for special tournament rules
def create_custom_pairings(tournament, round) do
  active_participants = get_active_participants(tournament)

  # Custom logic here - e.g., seeded brackets, regional groupings, etc.
  custom_groupings = apply_custom_logic(active_participants)

  # Convert to standard pairing format
  create_pairing_structs(custom_groupings, tournament.id, round.id)
end
```

### Pairing Analysis

```elixir
# Analyze pairing history for fairness
def analyze_opponent_distribution(tournament) do
  pairings = get_all_tournament_pairings(tournament)

  opponent_counts = pairings
  |> build_opponent_matrix()
  |> calculate_pairing_frequency()
  |> identify_imbalances()

  generate_fairness_report(opponent_counts)
end
```

The pairing system provides sophisticated, format-aware algorithms that ensure fair and engaging tournament experiences while handling the complex edge cases inherent in multiplayer Magic: The Gathering tournaments.
