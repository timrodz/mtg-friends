defmodule MtgFriends.TournamentUtilsTest do
  use MtgFriends.DataCase
  alias MtgFriends.TournamentUtils

  describe "get_overall_scores/1" do
    test "correctly maps and sorts participants by total score and win rate" do
      participants = [
        %{id: 1, points: 5, win_rate: 50.0},
        %{id: 2, points: 5, win_rate: 0.0},
        %{id: 3, points: 5, win_rate: 0.0},
        %{id: 4, points: 5, win_rate: 50.0},
        %{id: 5, points: 2, win_rate: 0.0},
        %{id: 6, points: 4, win_rate: 0.0},
        %{id: 7, points: 6, win_rate: 0.0},
        %{id: 8, points: 8, win_rate: 100.0}
      ]

      results = TournamentUtils.get_overall_scores(participants)

      assert length(results) == 8

      [first, second, third, fourth, fifth, sixth, seventh, eighth] = results

      # 1st: 8 points, 100% win rate (Player 8)
      assert first.id == 8
      assert first.total_score == 8
      assert first.win_rate == Decimal.from_float(100.0)

      # 2nd: 6 points (Player 7)
      assert second.id == 7
      assert second.total_score == 6

      # 3rd/4th: 5 points, 50% win rate (Player 1 and 4)
      # Order between equal score/win_rate is not strictly defined, but they should be next
      assert third.id in [1, 4]
      assert third.total_score == 5
      assert third.win_rate == Decimal.from_float(50.0)

      assert fourth.id in [1, 4]
      assert fourth.total_score == 5

      # 5th/6th: 5 points, 0% win rate (Player 2 and 3)
      assert fifth.id in [2, 3]
      assert fifth.total_score == 5
      assert fifth.win_rate == Decimal.from_float(0.0)

      assert sixth.id in [2, 3]

      # 7th: 4 points (Player 6)
      assert seventh.id == 6
      assert seventh.total_score == 4

      # 8th: 2 points (Player 5)
      assert eighth.id == 5
      assert eighth.total_score == 2
    end

    test "handles empty participants" do
      assert TournamentUtils.get_overall_scores([]) == []
    end
  end
end
