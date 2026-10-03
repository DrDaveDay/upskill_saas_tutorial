class Result < ApplicationRecord
  belongs_to :user

  validates :game, inclusion: { in: Game::KEYS }
  validates :played_on, presence: true
  validates :game, uniqueness: { scope: [ :user_id, :played_on ], message: "already has a score for that day" }
  validate :score_fits_game

  before_validation :compute_points

  scope :for_month, ->(month) { where(played_on: month.beginning_of_month..month.end_of_month) }
  scope :on, ->(date) { where(played_on: date) }

  def game_definition = Game.find(game)
  def summary = game_definition.summary_for(self)

  # Saves a parsed share result, replacing any earlier entry for the same game and day.
  def self.record!(user:, played_on:, attributes:)
    result = user.results.find_or_initialize_by(game: attributes[:game], played_on: played_on)
    result.assign_attributes(attributes.slice(:puzzle_number, :solved, :score_value, :breakdown, :share_text))
    result.save!
    result
  end

  private
    def compute_points
      self.solved = breakdown.to_s.split(",").size == 4 && breakdown.exclude?("X") if game == "quordle"
      self.points = Game::KEYS.include?(game) ? game_definition.points_for(self) : 0
    end

    def score_fits_game
      return unless Game::KEYS.include?(game)

      case game
      when "wordle"
        errors.add(:score_value, "must be 1–6 guesses") if solved? && !(1..6).cover?(score_value)
      when "waffle"
        errors.add(:score_value, "must be 0–5 stars") if solved? && !(0..5).cover?(score_value)
      when "quordle"
        words = breakdown.to_s.split(",")
        valid = words.size == 4 && words.all? { |w| w.strip.upcase == "X" || (1..9).cover?(w.to_i) }
        errors.add(:breakdown, "needs four guess counts (1–9, or X for missed)") unless valid
      when "connections"
        errors.add(:score_value, "must be 0–3 mistakes when solved") if solved? && !(0..3).cover?(score_value)
        errors.add(:breakdown, "must be 0–3 groups found") if !solved? && !(0..3).cover?(breakdown.to_i)
      when "one_word_search"
        errors.add(:score_value, "must be a time in seconds") if solved? && score_value.to_i <= 0
      end
    end
end
