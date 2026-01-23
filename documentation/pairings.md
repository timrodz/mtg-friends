# Pairing System Documentation

## Overview

The pairing system is the heart of tournament management in MTG Friends, responsible for matching players together in optimal groups for each round. It implements sophisticated algorithms to ensure fair play, minimize repeat opponents, and handle the unique requirements of different Magic: The Gathering formats.

## Architecture

### Core Components

The pairing system is structured across multiple modules with clear separation of concerns:

- **Pairings Context** - Main entry point, CRUD operations, and pairing algorithms
- **Pairing Schema** - Database schema and validation
- **TournamentRenderer** - Display logic
- **Participants** - Scoring logic

### Database Schema

The `pairings` table acts as a container for a match or pod. The actual players involved are linked via a join table.

- **Active**: Boolean flag indicating if the pairing is currently active.
- **Relationships**:
  - Belongs to a Tournament and a Round.
  - Has many `pairing_participants` (join table).
  - Has many `participants` through the join table.
  - Belongs to a `winner` (referencing a `pairing_participant`).
- **Timestamps**: Standard creation and update tracking.

**Key Relationships:**

- Each pairing belongs to exactly one tournament and one round.
- A pairing represents a group of players (pod or match).
- Participants are associated with the pairing through the `pairing_participants` table.
- The `winner` field on the pairing explicitly points to the winning participant record within that pairing context.

## Pairing Algorithms

### Algorithm Selection

The system chooses pairing algorithms based on round number and tournament configuration. Initial rounds often use random pairing, while subsequent rounds use Swiss or Bubble Round logic depending on the tournament subformat.

### 1. First Round (Random) Pairings

**Purpose:** Establish initial random matchups for fair tournament start.
**Algorithm:** Simple shuffle and partition.

**Characteristics:**

- **No History**: Ignores any previous matchups
- **Pure Random**: Uses a shuffle mechanism for unpredictable ordering
- **Format Aware**: Respects EDH pod sizes vs Standard match sizes

### 2. Swiss Pairing System

**Purpose:** Minimize repeat opponents while maintaining competitive balance.
**Algorithm:** Multi-retry optimization with opponent history tracking.

#### Swiss Algorithm Components

**Opponent History Matrix:**

The system builds a matrix of who has played whom by analyzing previous rounds. This allows it to identify valid opponents for each player.

**Optimal Pairing Attempt:**

- Creates groups prioritizing players who haven't faced each other
- Uses available opponent lists to find compatible pairings
- Falls back to retry system if optimal solution impossible

**Retry-Based Fallback:**

If an optimal solution isn't found immediately, the system attempts to generate valid pairings multiple times (up to a limit), shuffling the potential matches each time. It evaluates each attempt based on the number of repeated opponents and selects the best one.

**Quality Evaluation:**

- Counts how many previous opponents are in each pod/match
- Minimizes total "repeated opponent" score across all pairings
- Balances randomness with opponent avoidance

### 3. Bubble Rounds Pairing

**Purpose:** Group players of similar performance levels together.
**Algorithm:** Score-based grouping with shuffling within tiers.

**Characteristics:**

- **Performance Tiers**: Groups players with same point totals
- **Descending Order**: Higher-scoring players paired first
- **Within-Tier Randomness**: Shuffles players of equal performance
- **Competitive Balance**: Creates more evenly matched pods/games

### 4. Top Cut Pairings

**Purpose:** Create elimination bracket from top performers.
**Algorithm:** Score-based selection of top 4 players.

**Characteristics:**

- **Merit-Based**: Only top-scoring players advance
- **Final Round**: Typically used in last tournament round
- **Single Pairing**: All finalists in one decisive game/match
- **Winner-Take-All**: Determines tournament champion

## Format-Specific Logic

### EDH/Commander Format

**Pod Size Management:**

The system attempts to create pods of 4 players. If the total number of players doesn't divide evenly by 4, it creates 3-player pods as necessary to ensure everyone plays.

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

Standard pairings are simpler, always grouping players into pairs.

**Characteristics:**

- **Fixed Size**: Always 2 players per match
- **Bye Handling**: Odd numbers result in one player receiving a bye
- **Straightforward**: No complex pod size optimization needed

## Pairing Data Management

### Creating Pairings

**Bulk Creation Process:**

Pairings are created in bulk to ensure efficiency and consistency. All pairings for a round are inserted in a single database transaction.

**Benefits:**

- **Atomic Operations**: All pairings created in single transaction
- **Performance**: Bulk insert much faster than individual creates
- **Consistency**: Ensures all pairings have same timestamp
- **Error Recovery**: Transaction rollback if any pairing fails

### Updating Scores

**Score Collection Process:**

Scores are entered via a form. The system processes these inputs and updates the corresponding pairings.

**Winner Determination:**

- **Highest Score Wins**: Player with most points wins the pod/match.
- **Tie Handling**: No winner declared if multiple players tie for highest.
- **Explicit Winner Tracking**: The pairing record is updated to point to the winning participant (via `winner_id` association).

## Advanced Features

### Dropped Player Handling

**Filtering Logic:**

Players marked as "dropped" are filtered out before pairings are generated.

**Impact:**

- **Pairing Exclusion**: Dropped players not included in new pairings
- **Historical Data**: Previous pairings and scores preserved
- **Dynamic Adjustment**: Pod/match sizes adjust automatically
- **Re-entry**: Players can be un-dropped if rules allow

### Configuration Constants

**Pairing Engine Settings:**

The engine uses configurable constants for things like maximum retry attempts for Swiss pairings and preferred pod sizes for EDH.

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

The system evaluates the quality of a set of pairings by calculating a "cost" based on repeated opponents, choosing the set with the lowest cost.

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

1.  **Create Round**: A new round is initialized.
2.  **Generate Pairings**: The engine analyzes the tournament state and creates pairing records for the round. The system handles all necessary data reloading to ensure the pairing engine has the latest state.
3.  **Collect Scores**: After games are played, scores are submitted and processed in a transaction.

### Custom Pairing Requirements

**Overrides:**

While the standard algorithms cover most cases, the system is designed to allow for custom pairing logic if needed, such as manual overrides or special event rules.

### Pairing Analysis

The system provides capabilities to analyze pairing history, which is useful for verifying fairness and checking distribution of match-ups across a tournament.

The pairing system provides sophisticated, format-aware algorithms that ensure fair and engaging tournament experiences while handling the complex edge cases inherent in multiplayer Magic: The Gathering tournaments.
