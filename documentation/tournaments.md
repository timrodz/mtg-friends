# Tournament System Documentation

## Overview

The tournament system in MTG Friends is the core component that manages Magic: The Gathering tournaments from creation to completion. It supports multiple tournament formats (EDH/Commander and Standard) with sophisticated pairing algorithms and scoring systems.

## Architecture

### Core Components

The tournament system is built around several interconnected modules:

- **Tournaments Context** (`lib/mtg_friends/tournaments.ex`) - Main business logic and CRUD operations
- **Tournament Schema** (`lib/mtg_friends/tournaments/tournament.ex`) - Database schema and validation
- **Tournament LiveView** (`lib/mtg_friends_web/live/tournament_live/`) - User interface and real-time updates
- **Tournament Utils** (`lib/mtg_friends/tournament_utils.ex`) - Core utilities and scoring functions
- **Tournament Renderer** (`lib/mtg_friends/tournament_renderer.ex`) - Display logic and formatting

### Database Schema

```elixir
schema "tournaments" do
  field :name, :string
  field :location, :string
  field :date, :naive_datetime
  field :description_raw, :string      # Raw markdown-like content
  field :description_html, :string     # Processed HTML with card links
  field :round_length_minutes, :integer, default: 60
  field :is_top_cut_4, :boolean, default: false
  field :round_count, :integer, default: 4
  field :status, Ecto.Enum, values: [:inactive, :active, :finished], default: :inactive
  field :format, Ecto.Enum, values: [:edh, :standard], default: :edh
  field :subformat, Ecto.Enum, values: [:bubble_rounds, :swiss], default: :bubble_rounds

  belongs_to :user, MtgFriends.Accounts.User
  belongs_to :game, MtgFriends.Games.Game
  has_many :participants, MtgFriends.Participants.Participant
  has_many :rounds, MtgFriends.Rounds.Round
end
```

## Tournament Lifecycle

### 1. Creation Phase

**Location:** `Tournaments.create_tournament/1`

```elixir
def create_tournament(attrs \\ %{}) do
  %Tournament{}
  |> Tournament.changeset(attrs)
  |> validate_description(attrs)  # Processes [[Card Name]] syntax
  |> Repo.insert()
end
```

**Key Features:**

- **Scryfall Integration**: Processes description text to convert `[[Card Name]]` syntax into clickable links with card images
- **Validation Requirements**: Name (min 5 chars), location (min 5 chars), description (min 20 chars)
- **Default Settings**: 60-minute rounds, 4 total rounds, Swiss subformat, EDH format
- **User Association**: Links tournament to creating user and selected game format

### 2. Configuration Phase

**Format Options:**

- **EDH/Commander**: 3-4 player pods, multiplayer scoring
- **Standard**: 2-player matches, traditional scoring

**Subformat Options:**

- **Swiss**: Avoids repeat opponents, balances win records
- **Bubble Rounds**: Groups players by similar performance scores

**Special Features:**

- **Top Cut**: Optional top-4 elimination in final round
- **Round Count**: Configurable number of rounds (typically 3-4)
- **Time Management**: Round length in minutes for time tracking

### 3. Participant Management

**Registration Process:**

```elixir
# Individual participant creation
Participants.create_participant(%{
  name: "Player Name",
  tournament_id: tournament.id,
  user_id: user.id,
  decklist: "Optional decklist"
})

# Bulk participant creation
Participants.create_x_participants(tournament_id, count)
```

**Participant Features:**

- **Name & Decklist**: Player identification and deck information
- **Drop System**: Players can be marked as dropped (`is_dropped: true`)
- **Points Tracking**: Cumulative points across all rounds
- **Winner Designation**: Tournament winner flag (`is_tournament_winner`)
- **User Association**: Optional link to registered user accounts

### 4. Tournament Execution

**Status Progression:**

1. **`:inactive`** - Setup phase, adding participants
2. **`:active`** - Tournament running, rounds being played
3. **`:finished`** - Tournament completed, winner declared

**Round Creation Process:**

```elixir
# Create new round
{:ok, round} = Rounds.create_round_for_tournament(tournament.id, round_number)

# Generate pairings using sophisticated algorithms
{:ok, %{insert_all: {pairing_count, _}}} =
  TournamentUtils.create_pairings(tournament, round)
```

### 5. Scoring System

**Score Calculation:** `TournamentUtils.get_overall_scores/2`

The scoring system uses a sophisticated algorithm that considers:

1. **Base Points**: Direct points earned in each round (0-3 typically)
2. **Positional Bonuses**: Small decimal bonuses based on pod/pairing position
3. **Win Rate**: Percentage of rounds won for tiebreaking
4. **Decimal Precision**: Scores calculated to 3 decimal places for fine-grained ranking

## Tournament Formats

### EDH/Commander Format

**Characteristics:**

- **Pod Size**: 3-4 players per pod
- **Scoring**: Points based on performance in multiplayer games
- **Pairing Logic**: Creates balanced pods considering previous opponents
- **Special Cases**: Handles odd numbers (6→2 pods of 3, 9→3 pods of 3)

**Pod Calculation:**

```elixir
def calculate_num_pairings(participant_count, :edh) do
  round(Float.ceil(participant_count / 4))  # 4 players per pod typically
end
```

### Standard Format

**Characteristics:**

- **Match Size**: 2 players per match
- **Scoring**: Traditional win/loss with points
- **Pairing Logic**: Swiss system or bracket-style elimination
- **Efficiency**: Simpler pairing algorithm than EDH

**Match Calculation:**

```elixir
def calculate_num_pairings(participant_count, :standard) do
  round(Float.ceil(participant_count / 2))  # 2 players per match
end
```

## Advanced Features

### Scryfall Card Integration

The tournament description system integrates with Scryfall API to enhance card references:

```elixir
defp validate_description(description_raw) do
  cards_to_search = Regex.scan(~r/\[\[(.*?)\]\]/, description_raw)

  # Fetch card data from Scryfall API
  cards_data = fetch_card_data_from_scryfall(cards_to_search)

  # Convert [[Card Name]] to clickable links with images
  String.replace(description_raw, cards_names_to_search, fn og_name ->
    metadata = find_card_metadata(cards_data, og_name)
    "<a class=\"underline\" target=\"_blank\" href=\"#{metadata.image_uri}\">#{metadata.name}</a>"
  end)
end
```

### Real-time Updates

The tournament system uses Phoenix LiveView for real-time updates:

- **Live Participant Lists**: Updates as players are added/removed
- **Live Scoring**: Real-time score updates during rounds
- **Status Changes**: Immediate reflection of tournament state changes
- **Leaderboards**: Dynamic ranking updates based on latest scores

### Admin Features

**Tournament Management:**

- **Status Control**: Activate, pause, or finish tournaments
- **Participant Management**: Add/remove/edit participants
- **Round Control**: Create rounds, input scores, manage pairings
- **Winner Selection**: Mark tournament winners

**Bulk Operations:**

- **Mass Participant Creation**: Create multiple empty participant slots
- **Batch Score Updates**: Update all scores for a round simultaneously
- **Tournament Cloning**: Copy tournament settings for new events

## Usage Patterns

### Creating a Tournament

```elixir
# 1. Create tournament
{:ok, tournament} = Tournaments.create_tournament(%{
  name: "FNM Commander Night",
  date: ~N[2024-01-15 19:00:00],
  location: "Local Game Store",
  description_raw: "Casual EDH tournament featuring [[Sol Ring]] and other classics!",
  game_id: game.id,
  user_id: user.id,
  format: :edh,
  subformat: :swiss,
  round_count: 3,
  is_top_cut_4: false
})

# 2. Add participants
participants = add_participants(tournament, 12)

# 3. Start tournament
Tournaments.update_tournament(tournament, %{status: :active})

# 4. Create and run rounds
for round_num <- 0..(tournament.round_count - 1) do
  {:ok, round} = Rounds.create_round_for_tournament(tournament.id, round_num)
  {:ok, _pairings} = TournamentUtils.create_pairings(tournament, round)
  # ... collect scores and update pairings
end

# 5. Finish tournament
Tournaments.update_tournament(tournament, %{status: :finished})
```

### Retrieving Tournament Data

```elixir
# Get full tournament with all associations
tournament = Tournaments.get_tournament!(id)
# Includes: participants, rounds with pairings, game info

# Get tournament scores and rankings
scores = TournamentUtils.get_overall_scores(
  tournament.rounds,
  TournamentUtils.get_num_pairings(length(tournament.participants), tournament.format)
)
```

## Error Handling and Edge Cases

### Validation Errors

- **Insufficient Participants**: Minimum 4 players required
- **Invalid Names**: Empty or missing participant names
- **Date Conflicts**: Past dates or invalid datetime formats
- **Description Length**: Minimum 20 characters required

### Runtime Edge Cases

- **Dropped Participants**: Excluded from future pairings but retain historical data
- **Odd Numbers**: Special logic for EDH pods (6→2x3, 9→3x3, 10→2x4+1x3)
- **Network Failures**: Graceful fallback when Scryfall API unavailable
- **Concurrent Updates**: Database transactions prevent data corruption

### Performance Considerations

- **Preloading**: Strategic preloading of associations in queries
- **Pagination**: Tournament lists paginated for large datasets
- **Caching**: Score calculations cached until round completion
- **Background Jobs**: Scryfall API calls can be backgrounded for large descriptions

This tournament system provides a robust, scalable foundation for managing Magic: The Gathering tournaments with sophisticated pairing algorithms, real-time updates, and comprehensive score tracking.
