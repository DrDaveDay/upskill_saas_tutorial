# The five supported daily puzzles. Every game is normalised to 0–6 points per
# day so that no single game dominates the monthly leaderboard.
class Game
  MAX_POINTS = 6

  attr_reader :key, :name, :emoji, :url, :how_to_share

  def initialize(key:, name:, emoji:, url:, how_to_share:)
    @key, @name, @emoji, @url, @how_to_share = key, name, emoji, url, how_to_share
  end

  ALL = [
    new(key: "wordle", name: "Wordle", emoji: "🟩", url: "https://www.nytimes.com/games/wordle",
        how_to_share: "Tap Share on the results screen."),
    new(key: "waffle", name: "Waffle", emoji: "🧇", url: "https://wafflegame.net/daily",
        how_to_share: "Tap Share under your finished waffle."),
    new(key: "quordle", name: "Quordle", emoji: "🔢", url: "https://www.merriam-webster.com/games/quordle",
        how_to_share: "Tap Share / Copy on the results screen."),
    new(key: "connections", name: "Connections", emoji: "🟪", url: "https://www.nytimes.com/games/connections",
        how_to_share: "Tap Share Your Results."),
    new(key: "one_word_search", name: "One Word Search", emoji: "🔍", url: "https://www.google.com/search?q=one+word+search+daily",
        how_to_share: "Tap Share after you find the word.")
  ].freeze

  KEYS = ALL.map(&:key).freeze

  def self.find(key)
    ALL.find { |game| game.key == key.to_s } or raise ArgumentError, "Unknown game: #{key}"
  end

  # Points for a result, 0..MAX_POINTS.
  def points_for(result)
    case key
    when "wordle"
      result.solved? ? (7 - result.score_value).clamp(1, 6) : 0
    when "waffle"
      result.solved? ? (result.score_value + 1).clamp(1, 6) : 0
    when "quordle"
      words = quordle_words(result.breakdown)
      return 0 if words.empty?
      per_word = words.map { |n| n ? (10 - n).clamp(1, 6) : 0 }
      (per_word.sum / 4.0).round(1)
    when "connections"
      result.solved? ? (6 - result.score_value.to_i).clamp(3, 6) : result.breakdown.to_i * 0.5
    when "one_word_search"
      return 0 unless result.solved?
      seconds = result.score_value.to_i
      if seconds <= 30 then 6
      elsif seconds <= 60 then 5
      elsif seconds <= 90 then 4
      elsif seconds <= 120 then 3
      elsif seconds <= 180 then 2
      else 1
      end
    end
  end

  # Short human summary such as "4/6", "3★" or "1 mistake".
  def summary_for(result)
    case key
    when "wordle"
      result.solved? ? "#{result.score_value}/6" : "X/6"
    when "waffle"
      result.solved? ? "#{result.score_value}★" : "X/5"
    when "quordle"
      quordle_words(result.breakdown).map { |n| n || "X" }.join("-")
    when "connections"
      if result.solved?
        mistakes = result.score_value.to_i
        mistakes.zero? ? "Perfect" : "#{mistakes} #{"mistake".pluralize(mistakes)}"
      else
        "#{result.breakdown.to_i}/4 groups"
      end
    when "one_word_search"
      return "Not found" unless result.solved?
      seconds = result.score_value.to_i
      format("%d:%02d", seconds / 60, seconds % 60)
    end
  end

  def to_param = key

  private
    # "6,5,X,8" => [6, 5, nil, 8]
    def quordle_words(breakdown)
      breakdown.to_s.split(",").map { |part| part.strip.upcase == "X" ? nil : part.to_i }
    end
end
