require "test_helper"

class ResultTest < ActiveSupport::TestCase
  setup { @user = users(:one) }

  test "scores each game out of six" do
    assert_equal 6, points(game: "wordle", solved: true, score_value: 1)
    assert_equal 1, points(game: "wordle", solved: true, score_value: 6)
    assert_equal 0, points(game: "wordle", solved: false)
    assert_equal 6, points(game: "waffle", solved: true, score_value: 5)
    assert_equal 1, points(game: "waffle", solved: true, score_value: 0)
    assert_equal 6, points(game: "quordle", breakdown: "4,3,2,1")
    assert_equal 2.8, points(game: "quordle", breakdown: "6,5,X,8")
    assert_equal 6, points(game: "connections", solved: true, score_value: 0)
    assert_equal 3, points(game: "connections", solved: true, score_value: 3)
    assert_equal 1, points(game: "connections", solved: false, score_value: 4, breakdown: "2")
    assert_equal 6, points(game: "one_word_search", solved: true, score_value: 25)
    assert_equal 1, points(game: "one_word_search", solved: true, score_value: 600)
  end

  test "rejects impossible scores" do
    assert_not build(game: "wordle", solved: true, score_value: 7).valid?
    assert_not build(game: "quordle", breakdown: "4,5").valid?
  end

  test "one result per game per day, re-recording replaces it" do
    Result.record!(user: @user, played_on: Date.current, attributes: { game: "wordle", solved: true, score_value: 5 })
    Result.record!(user: @user, played_on: Date.current, attributes: { game: "wordle", solved: true, score_value: 2 })
    assert_equal [ 5 ], @user.results.pluck(:points).map(&:to_i)
  end

  private
    def build(attrs) = Result.new({ user: @user, played_on: Date.current }.merge(attrs))

    def points(attrs)
      result = build(attrs)
      assert result.valid?, result.errors.full_messages.inspect
      result.points.to_f
    end
end
