# Tournament System Documentation

## Overview

The tournament system in MTG Friends is the core component that manages Magic: The Gathering tournaments from creation to completion. It supports multiple tournament formats (EDH/Commander and Standard) with sophisticated pairing algorithms and scoring systems.

## Architecture

### Core Components

The tournament system is built around several interconnected modules:

- **Tournaments Context** - Main business logic and CRUD operations
- **Tournament Schema** - Database schema and validation
- **Tournament LiveView** - User interface and real-time updates
- **Tournament LiveView** - User interface and real-time updates
- **Tournament Renderer** - Display logic and formatting

### Database Schema

Tournaments track essential details about the event, its configuration, and its lifecycle.

- **Basic Info**: Name, location, date, and descriptions (raw markdown and processed HTML).
- **Configuration**:
  - **Round Length**: Default 60 minutes.
  - **Top Cut**: Optional top-4 elimination.
  - **Round Count**: Default 4 rounds.
  - **Format**: EDH (default) or Standard.
  - **Subformat**: Bubble Rounds (default) or Swiss.
- **State**: Current status (inactive, active, finished).
- **Relationships**:
  - Belongs to a User (organizer) and a Game type.
  - Has many Participants and Rounds.

## Tournament Lifecycle

### 1. Creation Phase

**Location**: `Tournaments.create_tournament`

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

Participants can be added individually or in bulk. They are linked to the tournament and optionally to a registered user account.

**Participant Features:**

- **Name & Decklist**: Player identification and deck information
- **Drop System**: Players can be marked as dropped
- **Points Tracking**: Cumulative points across all rounds
- **Winner Designation**: Tournament winner flag
- **User Association**: Optional link to registered user accounts

### 4. Tournament Execution

**Status Progression:**

1.  **Inactive** - Setup phase, adding participants
2.  **Active** - Tournament running, rounds being played
3.  **Finished** - Tournament completed, winner declared

**Round Creation Process:**

Rounds are created sequentially. As each round initializes, pairings are generated using the tournament's selected pairing algorithm (Swiss, Random, etc.).

### 5. Scoring System

**Score Calculation:**

The scoring system uses a sophisticated algorithm that considers:

1.  **Base Points**: Direct points earned in each round (typically 0-3).
2.  **Positional Bonuses**: Small decimal bonuses based on pod/pairing position to break ties.
3.  **Win Rate**: The percentage of rounds won. This is a key tiebreaker.
4.  **Decimal Precision**: Scores calculated to 3 decimal places for fine-grained ranking.

## Tournament Formats

### EDH/Commander Format

**Characteristics:**

- **Pod Size**: 3-4 players per pod
- **Scoring**: Points based on performance in multiplayer games
- **Pairing Logic**: Creates balanced pods considering previous opponents
- **Special Cases**: Handles odd numbers (6→2 pods of 3, 9→3 pods of 3)

**Pod Calculation:**

The system attempts to group players into pods of 4. If that's not possible, it mixes 3-player and 4-player pods to ensure everyone plays.

### Standard Format

**Characteristics:**

- **Match Size**: 2 players per match
- **Scoring**: Traditional win/loss with points
- **Pairing Logic**: Swiss system or bracket-style elimination
- **Efficiency**: Simpler pairing algorithm than EDH

**Match Calculation:**

For standard format, players are simply paired off. If there's an odd number of players, bye logic applies.

## Advanced Features

### Scryfall Card Integration

The tournament description system integrates with Scryfall API to enhance card references. When a description is saved, the system detects `[[Card Name]]` patterns, fetches metadata from Scryfall, and replaces the text with rich HTML links that show card images on hover/click.

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

1.  **Define Details**: Set name, date, location, and description.
2.  **Configure Rules**: Choose format (EDH/Standard), subformat (Swiss/Bubble), and round count.
3.  **Add Players**: Register participants.
4.  **Start**: Activate the tournament.
5.  **Run Rounds**: Iterate through rounds, generating pairings and recording scores.
6.  **Conclude**: Finish the tournament and declare winners.

### Retrieving Tournament Data

The system allows retrieval of comprehensive tournament data, including full participant lists, round histories, and calculated standings. Standings are sorted by total score and win rate.

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
