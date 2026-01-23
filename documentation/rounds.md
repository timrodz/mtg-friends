# Rounds System Documentation

## Overview

The rounds system in MTG Friends manages the temporal structure of tournaments, dividing tournament play into discrete time periods with their own pairings, scoring, and status tracking. Each round represents a complete cycle of games played simultaneously across all participants.

## Architecture

### Core Components

The rounds system is organized around several interconnected modules:

- **Rounds Context** - CRUD operations and business logic
- **Round Schema** - Database schema and validation
- **Integration with Tournaments** - Rounds belong to tournaments and contain pairings
- **LiveView Integration** - Real-time round management through web interface

### Database Schema

Rounds are stored with the following key data points:

- **Status**: Tracks the lifecycle, defaulting to inactive
- **Number**: Sequential identifier (0-indexed)
- **Started At**: Timestamp for when the round officially began
- **Relationships**: Belongs to a Tournament and has many Pairings
- **Timestamps**: Standard creation and update tracking

**Key Relationships:**

- Each round belongs to exactly one tournament
- Each round contains multiple pairings (player groupings)
- Rounds are numbered sequentially starting from 0
- Status tracks the lifecycle of each round

## Round Lifecycle

### 1. Round Creation

**Creation Context:**

- **Tournament Association**: Round immediately linked to parent tournament
- **Sequential Numbering**: Round numbers assigned sequentially (0, 1, 2, ...)
- **Default Status**: Rounds start in an inactive status
- **Timestamp Tracking**: Automatic insertion and update timestamps

**Typical Creation Flow:**

Rounds are typically created in a loop based on the tournament's configured round count. As each round is created, it is linked to the tournament. Pairings are then generated for the round using the tournament's pairing engine, creating the matchups for that specific round.

### 2. Round Status Management

**Status Progression:**

Inactive -> Active -> Finished

**Status Meanings:**

- **Inactive** - Round created but not yet started, pairings may be generated
- **Active** - Round currently being played, scores being collected
- **Finished** - Round completed, all scores recorded, ready for next round

**Status Transitions:**

Rounds transition from inactive to active when a tournament organizer starts the round. This sets a timestamp. When all games are complete and scores are entered, the round is moved to finished status.

### 3. Round Data Retrieval

**Basic Retrieval:**

Rounds can be looked up by their ID. Optionally, related data like the tournament (with its participants) and pairings (with their participants) can be preloaded for complete context.

**Tournament-Context Retrieval:**

Rounds can also be retrieved by specifying the tournament ID and the round number. This is common when navigating through a tournament's history. For user interfaces that use 1-based indexing (Round 1, Round 2), the system handles the conversion to the 0-based storage index used in the database.

## Round Management Features

### Preloading Strategies

**Selective Preloading:**

The system supports fetching rounds with or without their associations. This optimization ensures that:

- **Performance Control**: Only load associated data when needed
- **Memory Efficiency**: Avoid loading unnecessary associations
- **Query Optimization**: Single query with joins vs multiple queries

### Tournament Integration

**Round-Tournament Relationship:**

When fetching rounds within a tournament context, deep loading of associations is often employed. This includes the parent tournament (and its participants), sibling rounds (for scoring calculations), and nested pairings with participant details.

### Display Number Conversion

**UI Integration:**

The database stores rounds with a 0-based index (0, 1, 2...), but users expect to see Round 1, Round 2, etc. The system handles this translation seamlessly, converting user input strings into the correct database integer values.

## Round State Management

### Active Round Detection

**Current Round Logic:**

The system identifies the current round by checking the sequence of rounds. If the last created round is not yet finished, it is considered the "active" or "current" round.

**Usage Patterns:**

- **UI State**: Controls whether round management UI is shown
- **Button States**: Enables/disables "Start Round", "End Round" buttons
- **Validation**: Prevents creating new rounds while current round active

### Round Progression Logic

**Sequential Round Creation:**

Moving to the next round involves creating the next sequential round record, generating pairings for it based on current scores, and then activating it. This process can only occur if the tournament round limit has not been reached.

### Time Tracking

**Round Timing:**

The start time is recorded when a round becomes active. Duration can be calculated by comparing this start time to when the round was marked as finished.

## Integration with Other Systems

### Pairing System Integration

**Round-Pairing Relationship:**

- Each round contains multiple pairings
- Pairings are created immediately after round creation
- Round status affects pairing behavior (scoring only when active)

**Typical Workflow:**

1.  Round is created.
2.  Pairings are generated.
3.  Round is set to active for play.

### Tournament System Integration

**Round Limits:**

Tournaments have a pre-defined number of rounds. The system enforces this limit, preventing the creation of rounds beyond the scheduled count.

**Special Round Logic:**

The final round is detected by comparing the round number to the tournament's total round count. This allows for special logic, such as triggering a "Top Cut" elimination bracket for the top 4 players instead of standard pairings.

### Scoring System Integration

**Score Collection Context:**

Rounds provide the container for score updates. Scores are submitted for pairings within a specific round, and these updates are processed transactionally to ensure data integrity.

## LiveView Integration

### Real-time Round Management

**Round Status Updates:**

The web interface allows organizers to start rounds with a button press. This updates the round status and broadcasts the change to all connected clients, ensuring everyone sees the "Active" status immediately.

**Dynamic UI Updates:**

- Round status changes trigger UI reloads
- Button states update based on round status
- Timer displays track active round duration

### Form Integration

**Round Management Forms:**

LiveView forms allow for editing round details or pairings. Changes made in these forms are validated and saved to the database, providing immediate feedback to the user.

## Error Handling and Edge Cases

### Validation Errors

**Required Operations:**

- Validating tournament linkage
- Ensuring non-negative, sequential round numbers
- Enforcing valid status values

**Business Logic Validation:**

- Checking against tournament round limits
- Preventing duplicate round numbers
- Ensuring round numbers are not negative

### State Management Issues

**Invalid Status Transitions:**

The system enforces a logical flow for status updates: Inactive -> Active -> Finished. Logic exists to validate these transitions and allow skipping to finished if necessary.

**Concurrent Round Management:**

- Database constraints prevent duplicate round numbers
- Transaction isolation prevents race conditions
- Optimistic locking ensures safe concurrent updates

### Data Integrity

**Orphaned Round Prevention:**

Foreign key constraints ensure that rounds cannot exist without a parent tournament. This prevents data inconsistency.

**Pairing Consistency:**

- Rounds cannot be deleted if they have pairings (referential integrity)
- Round status changes are validated against pairing states
- Cascade deletes ensure cleanup when tournaments removed

## Performance Considerations

### Query Optimization

**Strategic Preloading:**

The system offers flexibility in how much data is loaded. Full loading retrieves the complete tournament tree, while lighter queries fetch only the round and its immediate pairings.

**Batch Operations:**

When multiple rounds need to be created or updated at once, the system uses batch insert/update operations to interact with the database efficiently.

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

1.  **Tournament Creation**: Define round count.
2.  **Round Interval**: For each round:
    - Create the round record.
    - Generate pairings based on current standings.
    - Set status to active.
    - Play games and collect scores.
    - Set status to finished.
3.  **Completion**: Mark tournament as finished.

### Round Analysis

System utilities allow for analyzing rounds, such as calculating duration statistics or reviewing historical status transitions.

The rounds system provides the temporal framework that organizes tournament play into manageable segments while maintaining data integrity and supporting real-time tournament management through sophisticated state tracking and LiveView integration.
