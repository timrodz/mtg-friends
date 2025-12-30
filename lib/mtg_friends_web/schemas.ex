defmodule MtgFriendsWeb.Schemas do
  alias OpenApiSpex.Schema

  defmodule Tournament do
    require OpenApiSpex

    OpenApiSpex.schema(%{
      title: "Tournament",
      description: "A TCG Tournament",
      type: :object,
      properties: %{
        id: %Schema{type: :integer, description: "Tournament ID"},
        game_id: %Schema{type: :integer, description: "Game ID"},
        user_id: %Schema{type: :integer, description: "User ID"},
        name: %Schema{type: :string, description: "Tournament Name"},
        date: %Schema{type: :string, format: :date, description: "Date of the tournament"},
        status: %Schema{
          type: :string,
          enum: ["inactive", "active", "finished"],
          description: "Tournament status"
        },
        location: %Schema{type: :string, description: "Tournament location"},
        description_raw: %Schema{type: :string, description: "Raw description (markdown)"},
        description_html: %Schema{type: :string, description: "Rendered HTML description"},
        round_length_minutes: %Schema{type: :integer, description: "Length of each round"},
        is_top_cut_4: %Schema{type: :boolean, description: "Whether there is a top 4 cut"},
        round_count: %Schema{type: :integer, description: "Number of rounds"},
        format: %Schema{
          type: :string,
          enum: ["standard", "edh"],
          description: "Tournament format"
        },
        subformat: %Schema{
          type: :string,
          enum: ["bubble_rounds", "swiss"],
          description: "Tournament subformat"
        },
        has_enough_participants: %Schema{
          type: :boolean,
          description: "Whether the tournament has enough participants"
        }
      },
      required: [:id, :name, :status],
      example: %{
        "id" => 1,
        "name" => "Friday Night Magic",
        "date" => "2023-10-27",
        "status" => "active",
        "location" => "Local Game Store"
      }
    })
  end

  defmodule TournamentRequest do
    require OpenApiSpex

    OpenApiSpex.schema(%{
      title: "TournamentRequest",
      type: :object,
      properties: %{
        name: %Schema{type: :string},
        date: %Schema{type: :string, format: :date},
        location: %Schema{type: :string},
        description_raw: %Schema{type: :string},
        round_length_minutes: %Schema{type: :integer},
        is_top_cut_4: %Schema{type: :boolean},
        round_count: %Schema{type: :integer},
        status: %Schema{type: :string, enum: ["inactive", "active", "finished"]},
        format: %Schema{type: :string},
        subformat: %Schema{type: :string},
        initial_participants: %Schema{
          type: :string,
          description: "List of participants, one per line"
        }
      }
    })
  end

  defmodule TournamentResponse do
    require OpenApiSpex

    OpenApiSpex.schema(%{
      title: "TournamentResponse",
      type: :object,
      properties: %{
        data: Tournament
      }
    })
  end

  defmodule TournamentsResponse do
    require OpenApiSpex

    OpenApiSpex.schema(%{
      title: "TournamentsResponse",
      type: :object,
      properties: %{
        data: %Schema{type: :array, items: Tournament}
      }
    })
  end

  defmodule Round do
    require OpenApiSpex

    OpenApiSpex.schema(%{
      title: "Round",
      type: :object,
      properties: %{
        id: %Schema{type: :integer},
        number: %Schema{type: :integer},
        status: %Schema{type: :string, enum: ["inactive", "active", "finished"]},
        started_at: %Schema{type: :string, format: :date_time},
        is_complete: %Schema{type: :boolean}
      }
    })
  end

  defmodule RoundRequest do
    require OpenApiSpex

    OpenApiSpex.schema(%{
      title: "RoundRequest",
      type: :object,
      properties: %{
        number: %Schema{type: :integer},
        status: %Schema{type: :string, enum: ["inactive", "active", "finished"]},
        started_at: %Schema{type: :string, format: :date_time},
        is_complete: %Schema{type: :boolean}
      }
    })
  end

  defmodule RoundResponse do
    require OpenApiSpex

    OpenApiSpex.schema(%{
      title: "RoundResponse",
      type: :object,
      properties: %{
        data: Round
      }
    })
  end

  defmodule Participant do
    require OpenApiSpex

    OpenApiSpex.schema(%{
      title: "Participant",
      type: :object,
      properties: %{
        id: %Schema{type: :integer},
        name: %Schema{type: :string},
        points: %Schema{type: :integer},
        decklist: %Schema{type: :string},
        is_tournament_winner: %Schema{type: :boolean},
        is_dropped: %Schema{type: :boolean},
        tournament_id: %Schema{type: :integer}
      }
    })
  end

  defmodule ParticipantRequest do
    require OpenApiSpex

    OpenApiSpex.schema(%{
      title: "ParticipantRequest",
      type: :object,
      properties: %{
        name: %Schema{type: :string},
        decklist: %Schema{type: :string},
        is_tournament_winner: %Schema{type: :boolean},
        is_dropped: %Schema{type: :boolean}
      },
      required: [:name]
    })
  end

  defmodule ParticipantResponse do
    require OpenApiSpex

    OpenApiSpex.schema(%{
      title: "ParticipantResponse",
      type: :object,
      properties: %{
        data: Participant
      }
    })
  end

  defmodule Pairing do
    require OpenApiSpex

    OpenApiSpex.schema(%{
      title: "Pairing",
      type: :object,
      properties: %{
        id: %Schema{type: :integer},
        number: %Schema{type: :integer},
        active: %Schema{type: :boolean},
        points: %Schema{type: :integer},
        winner: %Schema{type: :boolean},
        tournament_id: %Schema{type: :integer},
        round_id: %Schema{type: :integer},
        participant_id: %Schema{type: :integer}
      }
    })
  end

  defmodule PairingRequest do
    require OpenApiSpex

    OpenApiSpex.schema(%{
      title: "PairingRequest",
      type: :object,
      properties: %{
        number: %Schema{type: :integer},
        active: %Schema{type: :boolean},
        points: %Schema{type: :integer},
        winner: %Schema{type: :boolean}
      },
      required: [:number]
    })
  end

  defmodule PairingResponse do
    require OpenApiSpex

    OpenApiSpex.schema(%{
      title: "PairingResponse",
      type: :object,
      properties: %{
        data: Pairing
      }
    })
  end

  # Generic

  defmodule LoginRequest do
    require OpenApiSpex

    OpenApiSpex.schema(%{
      title: "LoginRequest",
      type: :object,
      properties: %{
        email: %Schema{type: :string, format: :email},
        password: %Schema{type: :string}
      },
      required: [:email, :password]
    })
  end

  defmodule LoginResponse do
    require OpenApiSpex

    OpenApiSpex.schema(%{
      title: "LoginResponse",
      type: :object,
      properties: %{
        data: %Schema{
          type: :object,
          properties: %{
            token: %Schema{type: :string},
            user: %Schema{
              type: :object,
              properties: %{
                id: %Schema{type: :integer},
                email: %Schema{type: :string, format: :email}
              }
            }
          }
        }
      }
    })
  end

  defmodule ErrorResponse do
    require OpenApiSpex

    OpenApiSpex.schema(%{
      title: "ErrorResponse",
      type: :object,
      properties: %{
        errors: %Schema{
          type: :object,
          additionalProperties: %Schema{type: :array, items: %Schema{type: :string}}
        }
      }
    })
  end
end
