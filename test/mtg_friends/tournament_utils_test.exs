defmodule MtgFriends.TournamentUtilsTest do
  use MtgFriends.DataCase
  alias MtgFriends.TournamentUtils

  describe "get_overall_scores/2" do
    test "correctly sums points and calculates win rates for tournament of 8 players and 2 rounds" do
      rounds = [
        %{
          id: 1,
          status: :finished,
          number: 1,
          pairings: [
            %{
              id: 101,
              round_id: 1,
              winner_id: 1001,
              # Assuming pairing.winner_id points to the pairing_participant.id of the winner
              pairing_participants: [
                %{id: 1001, participant_id: 1, points: 4},
                %{id: 1002, participant_id: 2, points: 3},
                %{id: 1003, participant_id: 3, points: 2},
                %{id: 1004, participant_id: 4, points: 1}
              ]
            },
            %{
              id: 102,
              round_id: 1,
              winner_id: 1008,
              # Assuming pairing.winner_id points to the pairing_participant.id of the winner
              pairing_participants: [
                %{id: 1005, participant_id: 5, points: 1},
                %{id: 1006, participant_id: 6, points: 2},
                %{id: 1007, participant_id: 7, points: 3},
                %{id: 1008, participant_id: 8, points: 4}
              ]
            }
          ]
        },
        %{
          id: 2,
          status: :finished,
          number: 2,
          pairings: [
            %{
              id: 201,
              round_id: 2,
              winner_id: 1004,
              pairing_participants: [
                %{id: 1001, participant_id: 1, points: 1},
                %{id: 1002, participant_id: 2, points: 2},
                %{id: 1003, participant_id: 3, points: 3},
                %{id: 1004, participant_id: 4, points: 4}
              ]
            },
            %{
              id: 202,
              round_id: 2,
              winner_id: 1008,
              pairing_participants: [
                %{id: 1005, participant_id: 5, points: 1},
                %{id: 1006, participant_id: 6, points: 2},
                %{id: 1007, participant_id: 7, points: 3},
                %{id: 1008, participant_id: 8, points: 4}
              ]
            }
          ]
        }
      ]

      # num_pairings isn't used in the new logic but was in the signature
      results = TournamentUtils.get_overall_scores(rounds)

      assert length(results) == 8

      p1_stats = Enum.find(results, &(&1.id == 1))
      p2_stats = Enum.find(results, &(&1.id == 2))
      p3_stats = Enum.find(results, &(&1.id == 3))
      p4_stats = Enum.find(results, &(&1.id == 4))
      p5_stats = Enum.find(results, &(&1.id == 5))
      p6_stats = Enum.find(results, &(&1.id == 6))
      p7_stats = Enum.find(results, &(&1.id == 7))
      p8_stats = Enum.find(results, &(&1.id == 8))

      assert p1_stats.total_score == 5
      assert p1_stats.win_rate == Decimal.from_float(50.0)

      assert p2_stats.total_score == 5
      assert p2_stats.win_rate == Decimal.from_float(0.0)

      assert p3_stats.total_score == 5
      assert p3_stats.win_rate == Decimal.from_float(0.0)

      assert p4_stats.total_score == 5
      assert p4_stats.win_rate == Decimal.from_float(50.0)

      assert p5_stats.total_score == 2
      assert p5_stats.win_rate == Decimal.from_float(0.0)

      assert p6_stats.total_score == 4
      assert p6_stats.win_rate == Decimal.from_float(0.0)

      assert p7_stats.total_score == 6
      assert p7_stats.win_rate == Decimal.from_float(0.0)

      assert p8_stats.total_score == 8
      assert p8_stats.win_rate == Decimal.from_float(100.0)
    end

    test "correctly sums points and calculates win rates for tournament of 7 players and 2 rounds" do
      rounds = [
        %{
          id: 1,
          status: :finished,
          number: 1,
          pairings: [
            %{
              id: 101,
              round_id: 1,
              winner_id: 1001,
              # Assuming pairing.winner_id points to the pairing_participant.id of the winner
              pairing_participants: [
                %{id: 1001, participant_id: 1, points: 4},
                %{id: 1002, participant_id: 2, points: 3},
                %{id: 1003, participant_id: 3, points: 2},
                %{id: 1004, participant_id: 4, points: 1}
              ]
            },
            %{
              id: 102,
              round_id: 1,
              winner_id: 1007,
              # Assuming pairing.winner_id points to the pairing_participant.id of the winner
              pairing_participants: [
                %{id: 1005, participant_id: 5, points: 2},
                %{id: 1006, participant_id: 6, points: 3},
                %{id: 1007, participant_id: 7, points: 4}
              ]
            }
          ]
        },
        %{
          id: 2,
          status: :finished,
          number: 2,
          pairings: [
            %{
              id: 201,
              round_id: 2,
              winner_id: 1004,
              pairing_participants: [
                %{id: 1001, participant_id: 1, points: 1},
                %{id: 1002, participant_id: 2, points: 2},
                %{id: 1003, participant_id: 3, points: 3},
                %{id: 1004, participant_id: 4, points: 4}
              ]
            },
            %{
              id: 202,
              round_id: 2,
              winner_id: 1007,
              pairing_participants: [
                %{id: 1005, participant_id: 5, points: 2},
                %{id: 1006, participant_id: 6, points: 3},
                %{id: 1007, participant_id: 7, points: 4}
              ]
            }
          ]
        }
      ]

      # num_pairings isn't used in the new logic but was in the signature
      results = TournamentUtils.get_overall_scores(rounds)

      assert length(results) == 7

      p1_stats = Enum.find(results, &(&1.id == 1))
      p2_stats = Enum.find(results, &(&1.id == 2))
      p3_stats = Enum.find(results, &(&1.id == 3))
      p4_stats = Enum.find(results, &(&1.id == 4))
      p5_stats = Enum.find(results, &(&1.id == 5))
      p6_stats = Enum.find(results, &(&1.id == 6))
      p7_stats = Enum.find(results, &(&1.id == 7))

      assert p1_stats.total_score == 5
      assert p1_stats.win_rate == Decimal.from_float(50.0)

      assert p2_stats.total_score == 5
      assert p2_stats.win_rate == Decimal.from_float(0.0)

      assert p3_stats.total_score == 5
      assert p3_stats.win_rate == Decimal.from_float(0.0)

      assert p4_stats.total_score == 5
      assert p4_stats.win_rate == Decimal.from_float(50.0)

      assert p5_stats.total_score == 4
      assert p5_stats.win_rate == Decimal.from_float(0.0)

      assert p6_stats.total_score == 6
      assert p6_stats.win_rate == Decimal.from_float(0.0)

      assert p7_stats.total_score == 8
      assert p7_stats.win_rate == Decimal.from_float(100.0)
    end

    test "handles empty rounds" do
      assert TournamentUtils.get_overall_scores([]) == []
    end
  end
end
