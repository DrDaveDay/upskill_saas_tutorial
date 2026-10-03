# Ranks a group's members by points for a month (or a single day).
class Leaderboard
  Row = Struct.new(:user, :rank, :points, :games_played, :days_played, :by_game, keyword_init: true) do
    def average = games_played.zero? ? 0 : (points / games_played).round(1)
  end

  attr_reader :group, :range

  def self.for_month(group, month) = new(group, month.beginning_of_month..month.end_of_month)
  def self.for_day(group, date) = new(group, date..date)

  def initialize(group, range)
    @group, @range = group, range
  end

  def rows
    @rows ||= begin
      results = Result.where(user: members, played_on: range).group_by(&:user_id)

      unranked = members.map do |user|
        mine = results.fetch(user.id, [])
        Row.new(
          user: user,
          points: mine.sum(&:points),
          games_played: mine.size,
          days_played: mine.map(&:played_on).uniq.size,
          by_game: mine.group_by(&:game).transform_values { |list| list.sum(&:points) }
        )
      end

      # Most points wins; ties go to whoever needed fewer games, then name.
      sorted = unranked.sort_by { |row| [ -row.points, row.games_played, row.user.name.downcase ] }
      sorted.each_with_index do |row, index|
        previous = sorted[index - 1] if index.positive?
        row.rank = previous && previous.points == row.points && previous.games_played == row.games_played ? previous.rank : index + 1
      end
    end
  end

  def leader
    rows.first if rows.first&.points&.positive?
  end

  private
    def members = @members ||= group.members.order(:name).to_a
end
