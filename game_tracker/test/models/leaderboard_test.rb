require "test_helper"

class LeaderboardTest < ActiveSupport::TestCase
  test "ranks members by points for the month" do
    alice, bob = users(:one), users(:two)
    group = Group.create_with_admin!(alice, name: "Family")
    group.memberships.create!(user: bob)

    today = Date.new(2026, 10, 15)
    Result.record!(user: alice, played_on: today, attributes: { game: "wordle", solved: true, score_value: 4 })
    Result.record!(user: bob, played_on: today, attributes: { game: "wordle", solved: true, score_value: 2 })
    Result.record!(user: bob, played_on: today - 1, attributes: { game: "waffle", solved: true, score_value: 5 })
    Result.record!(user: alice, played_on: Date.new(2026, 9, 30), attributes: { game: "wordle", solved: true, score_value: 1 })

    rows = Leaderboard.for_month(group, today).rows
    assert_equal [ bob, alice ], rows.map(&:user)
    assert_equal [ 11, 3 ], rows.map { |row| row.points.to_i }
    assert_equal [ 1, 2 ], rows.map(&:rank)
    assert_equal bob, Leaderboard.for_month(group, today).leader.user
  end

  test "ties share a rank and nobody leads with zero points" do
    group = Group.create_with_admin!(users(:one), name: "Office")
    group.memberships.create!(user: users(:two))
    board = Leaderboard.for_month(group, Date.current)
    assert_equal [ 1, 1 ], board.rows.map(&:rank)
    assert_nil board.leader
  end
end
