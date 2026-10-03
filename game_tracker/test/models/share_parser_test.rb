require "test_helper"

class ShareParserTest < ActiveSupport::TestCase
  test "parses a solved Wordle including hard mode" do
    result = parse_one("Wordle 1,567 3/6*\n\n⬛🟨⬛⬛⬛\n🟩🟩⬛🟩⬛\n🟩🟩🟩🟩🟩")
    assert_equal [ "wordle", 1567, true, 3 ], [ result.game, result.puzzle_number, result.solved, result.score_value ]
  end

  test "parses a failed Wordle" do
    result = parse_one("Wordle 1.567 X/6\n\n⬛⬛⬛⬛⬛")
    assert_equal false, result.solved
    assert_nil result.score_value
  end

  test "parses Waffle stars and failures" do
    assert_equal 4, parse_one("#waffle807 4/5\n\n🟩🟩🟩🟩🟩\n🔥 streak: 3\nwafflegame.net").score_value
    assert_equal false, parse_one("#waffle807 X/5\n\n💔").solved
  end

  test "parses Quordle keycap digits and missed words" do
    result = parse_one("Daily Quordle 1234\n6️⃣5️⃣\n🟥8️⃣\nm-w.com/games/quordle/\n⬜🟨⬜⬜⬜")
    assert_equal "6,5,X,8", result.breakdown
    assert_equal false, result.solved
  end

  test "parses Quordle digits without variation selector" do
    result = parse_one("Daily Quordle 1234\n4⃣5⃣\n6⃣7⃣")
    assert_equal "4,5,6,7", result.breakdown
    assert result.solved
  end

  test "parses Connections mistakes" do
    result = parse_one("Connections\nPuzzle #480\n🟨🟨🟨🟨\n🟩🟩🟦🟩\n🟩🟩🟩🟩\n🟦🟦🟦🟦\n🟪🟪🟪🟪")
    assert result.solved
    assert_equal 1, result.score_value
    assert_equal 480, result.puzzle_number
  end

  test "parses a failed Connections" do
    result = parse_one("Connections\nPuzzle #480\n🟨🟩🟨🟨\n🟨🟨🟨🟨\n🟩🟦🟩🟩\n🟩🟪🟩🟩\n🟦🟩🟦🟦")
    assert_not result.solved
    assert_equal "1", result.breakdown
    assert_equal 4, result.score_value
  end

  test "parses One Word Search times" do
    assert_equal 107, parse_one("One Word Search #212\nFound it in 1:47!").score_value
    assert_equal 42, parse_one("ONE WORD SEARCH\n42 seconds").score_value
    assert_not parse_one("One Word Search #212 ❌").solved
  end

  test "parses several games pasted together" do
    parser = ShareParser.parse("Wordle 1,567 4/6\n\n🟩🟩🟩🟩🟩\n\nConnections\nPuzzle #480\n🟨🟨🟨🟨\n🟩🟩🟩🟩\n🟦🟦🟦🟦\n🟪🟪🟪🟪")
    assert_equal %w[ wordle connections ], parser.results.map(&:game)
    assert_empty parser.errors
  end

  test "reports text it doesn't recognise" do
    parser = ShareParser.parse("I had a great day")
    assert_empty parser.results
    assert_match(/couldn't find/, parser.errors.first)
  end

  test "reports a recognised game it cannot score" do
    parser = ShareParser.parse("One Word Search\nI loved it")
    assert_empty parser.results
    assert_match(/One Word Search/, parser.errors.first)
  end

  private
    def parse_one(text)
      parser = ShareParser.parse(text)
      assert_equal 1, parser.results.size, parser.errors.inspect
      parser.results.first
    end
end
