# Turns the text copied from a game's "Share" button into result attributes.
#
# One paste may contain several games (e.g. someone copies Wordle, then
# Connections, into the same box), so the text is split at each game header
# and every chunk is parsed on its own.
class ShareParser
  Parsed = Struct.new(:game, :puzzle_number, :solved, :score_value, :breakdown, :share_text, keyword_init: true) do
    def attributes = to_h
  end

  HEADERS = {
    "wordle"          => /Wordle\s+#?[\d,.\s]*\d\s+[1-6X]\/6/i,
    "waffle"          => /#waffle\s*#?\d+/i,
    "quordle"         => /Daily\s+Quordle\s+#?\d+/i,
    "connections"     => /Connections\s*\n?\s*Puzzle\s*#\s*[\d,]+/i,
    "one_word_search" => /One\s*Word\s*Search/i
  }.freeze

  KEYCAP = /([1-9])️?⃣/
  RED_SQUARE = "\u{1F7E5}"
  CONNECTIONS_SQUARES = %W[\u{1F7E8} \u{1F7E9} \u{1F7E6} \u{1F7EA}].freeze # yellow green blue purple

  attr_reader :results, :errors

  def self.parse(text) = new(text).tap(&:parse)

  def initialize(text)
    @text = text.to_s.dup.force_encoding(Encoding::UTF_8).scrub.gsub("\r\n", "\n")
    @results = []
    @errors = []
  end

  def parse
    chunks = split_into_chunks
    @errors << "We couldn't find a Wordle, Waffle, Quordle, Connections or One Word Search result in that text." if chunks.empty?

    chunks.each do |game, chunk|
      parsed = send("parse_#{game}", chunk)
      if parsed
        @results << parsed
      else
        @errors << "Found #{Game.find(game).name} but couldn't read the score. Try manual entry."
      end
    end
    self
  end

  private
    def split_into_chunks
      starts = HEADERS.flat_map do |game, regex|
        positions = []
        @text.scan(regex) { positions << [ Regexp.last_match.begin(0), game ] }
        positions
      end.sort_by(&:first)

      starts.each_with_index.map do |(start, game), index|
        finish = starts[index + 1]&.first || @text.length
        [ game, @text[start...finish].strip ]
      end
    end

    def parse_wordle(chunk)
      match = chunk.match(/Wordle\s+#?([\d,.\s]*\d)\s+([1-6X])\/6/i) or return
      solved = match[2].upcase != "X"
      Parsed.new(game: "wordle", puzzle_number: digits(match[1]), solved: solved,
                 score_value: solved ? match[2].to_i : nil, share_text: chunk)
    end

    def parse_waffle(chunk)
      match = chunk.match(/#waffle\s*#?(\d+)\s+([0-5X])\/5/i) or return
      solved = match[2].upcase != "X"
      Parsed.new(game: "waffle", puzzle_number: match[1].to_i, solved: solved,
                 score_value: solved ? match[2].to_i : nil, share_text: chunk)
    end

    def parse_quordle(chunk)
      header = chunk.match(/Daily\s+Quordle\s+#?(\d+)/i) or return
      body = chunk[header.end(0)..]
      words = body.scan(/#{KEYCAP}|#{RED_SQUARE}/o).first(4).map { |(digit)| digit&.to_i }
      return unless words.size == 4

      Parsed.new(game: "quordle", puzzle_number: header[1].to_i, solved: words.none?(&:nil?),
                 score_value: words.sum { |n| n || 13 }, breakdown: words.map { |n| n || "X" }.join(","),
                 share_text: chunk)
    end

    def parse_connections(chunk)
      header = chunk.match(/Puzzle\s*#\s*([\d,]+)/i) or return
      rows = chunk.lines.map { |line| line.gsub(/[\s️]/, "") }
                  .select { |line| line.length == 4 && line.each_char.all? { |c| CONNECTIONS_SQUARES.include?(c) } }
      return if rows.empty?

      groups = rows.count { |row| row.chars.uniq.size == 1 }
      mistakes = rows.size - groups
      Parsed.new(game: "connections", puzzle_number: digits(header[1]), solved: groups == 4,
                 score_value: mistakes, breakdown: groups.to_s, share_text: chunk)
    end

    # One Word Search's share text is less standardised, so this is lenient: it
    # looks for a puzzle number and a time (m:ss or "42s").
    def parse_one_word_search(chunk)
      number = chunk.match(/#\s*(\d+)/)&.captures&.first&.to_i
      failed = chunk.match?(/not found|gave up|failed|❌/i)

      seconds =
        if (time = chunk.match(/(\d{1,2}):(\d{2})/))
          time[1].to_i * 60 + time[2].to_i
        elsif (time = chunk.match(/(\d+)\s*(?:s|sec|secs|seconds)\b/i))
          time[1].to_i
        end
      return if seconds.nil? && !failed

      Parsed.new(game: "one_word_search", puzzle_number: number, solved: !failed,
                 score_value: failed ? nil : seconds, share_text: chunk)
    end

    def digits(string) = string.to_s.gsub(/\D/, "").to_i
end
