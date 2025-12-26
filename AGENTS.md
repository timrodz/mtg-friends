# AGENTS.md

This file provides guidance to AI agents when working with code in this repository.

## Project Overview

MtgFriends is a Phoenix LiveView application for managing Magic: The Gathering tournaments. It supports different tournament formats (Commander/EDH and Standard) with various pairing algorithms and real-time tournament management.

## Development Commands

### Setup and Dependencies

```bash
# Initial setup - installs deps, sets up database, builds assets
mix setup

# Install dependencies only
mix deps.get

# Database operations
mix ecto.setup          # Create, migrate, seed
mix ecto.create        # Create database
mix ecto.migrate       # Run migrations
mix ecto.reset         # Drop and recreate database
```

### Development Server

```bash
# Start Phoenix server
mix phx.server

# Start with IEx console
iex -S mix phx.server

# Server runs on localhost:4000
```

### Testing

```bash
# Run all tests (creates test DB, migrates, runs tests)
mix test

# Run specific test file
mix test test/mtg_friends/tournaments_test.exs

# Run tests with coverage
mix test --cover
```

### Assets

```bash
# Build assets for development
mix assets.build

# Build and minify assets for production
mix assets.deploy

# Setup asset tools (Tailwind, esbuild)
mix assets.setup
```

## Architecture

### Context-Based Domain Design

The application follows Phoenix's context pattern with these main domains:

- **Accounts** (`lib/mtg_friends/accounts/`) - User management and authentication
- **Tournaments** (`lib/mtg_friends/tournaments/`) - Tournament CRUD and business logic
- **Participants** (`lib/mtg_friends/participants/`) - Tournament participant management
- **Rounds** (`lib/mtg_friends/rounds/`) - Tournament round management
- **Pairings** (`lib/mtg_friends/pairings/`) - Player pairing within rounds
- **Games** (`lib/mtg_friends/games/`) - Game format definitions

### Tournament Management System

The core tournament flow involves:

1. **Tournament Creation** - Define format, subformat, round count
2. **Participant Registration** - Players join tournaments
3. **Round Management** - Create rounds and generate pairings
4. **Pairing Algorithms** - Different strategies for different formats:
   - **Bubble Rounds**: Pair players by previous round standings
   - **Swiss**: Minimize repeat opponents across all rounds
5. **Scoring and Results** - Track points and determine winners

### Key Components

#### Tournament Formats

- **EDH/Commander**: 3-4 player pods
- **Standard**: 2 player matches

#### Pairing Logic (`lib/mtg_friends/tournament_utils.ex`)

Complex algorithms handle:

- Pod size calculation based on participant count
- Swiss pairing matrix to minimize repeat matches
- Bubble round groupings by performance
- Top cut bracket generation

### LiveView Architecture

- **Layouts** in `lib/mtg_friends_web/components/layouts/`
  - `landing.html.heex` for marketing pages
  - `app.html.heex` for authenticated app
- **Live Views** in `lib/mtg_friends_web/live/`
  - Tournament management in `tournament_live/`
  - Game management in `game_live/`
  - User authentication flows
- **Components** use Phoenix UI library extensions

### Database Schema

Key relationships:

- Tournaments → Participants (many-to-many through tournaments)
- Tournaments → Rounds → Pairings → Participants
- Users ← Participants (tournaments a user has joined)
- Games → Tournaments (format definitions)

### External Integration

- **Scryfall API** integration for Magic card lookups in tournament descriptions
- **SMTP/Email** via Swoosh for user notifications
- **Tailwind CSS** for styling with custom configuration

## Configuration

### Environment Setup

Create `.env` file with required configurations, then run `source .env` before starting development.

### Key Config Files

- `config/config.exs` - Base application configuration
- `config/dev.exs` - Development environment settings
- `config/prod.exs` - Production environment settings
- `mix.exs` - Project definition and dependencies

## Testing Strategy

- Unit tests for each context module
- LiveView integration tests for user workflows
- Fixtures in `test/support/fixtures/` provide test data
- Database isolation per test with `DataCase`

## Code Quality & Linting

### Code Formatting

```bash
# Format code (run before committing)
mix format

# Check if code is formatted
mix format --check-formatted
```

### Linting & Type Checking

```bash
# Run Credo for code analysis
mix credo

# Run Dialyzer for type checking (after first setup)
mix dialyzer

# Setup Dialyzer PLT files (first time only)
mix dialyzer --plt
```

## Development Guidelines

### Phoenix Conventions

- Follow Phoenix context patterns for domain separation
- Use LiveView components for interactive UI elements
- Keep business logic in context modules, not LiveViews
- Use `assigns` pattern for LiveView state management

### Database Guidelines

- Always create migrations for schema changes
- Use descriptive migration names with timestamps
- Add database constraints for data integrity
- Test migrations both up and down

### Testing Best Practices

- Write tests before implementing features (TDD)
- Test context functions separately from LiveViews
- Use factory functions from fixtures for test data
- Test both happy path and error scenarios

### Git Workflow

- Use feature branches for all changes
- Write descriptive commit messages
- Run tests before pushing code
- Keep commits focused and atomic
