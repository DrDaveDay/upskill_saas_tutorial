class ResultsController < ApplicationController
  def index
    @results = current_user.results.order(played_on: :desc, created_at: :desc).limit(200)
  end

  def new
    @played_on = Date.current
    @manual = Result.new(game: params[:game].presence || "wordle", played_on: @played_on, solved: true)
  end

  # Paste one or more share texts.
  def create
    played_on = parse_date(params[:played_on])
    parser = ShareParser.parse(params[:share_text])

    saved = parser.results.filter_map do |parsed|
      Result.record!(user: current_user, played_on: played_on, attributes: parsed.attributes)
    rescue ActiveRecord::RecordInvalid => e
      parser.errors << "#{Game.find(parsed.game).name}: #{e.record.errors.full_messages.to_sentence}"
      nil
    end

    if saved.any?
      notice = "Saved " + saved.map { |r| "#{r.game_definition.name} #{r.summary} (+#{format_points(r.points)})" }.join(", ")
      flash[:alert] = parser.errors.to_sentence if parser.errors.any?
      redirect_to after_save_path, notice: notice
    else
      @played_on = played_on
      @share_text = params[:share_text]
      @manual = Result.new(game: "wordle", played_on: played_on, solved: true)
      flash.now[:alert] = parser.errors.to_sentence
      render :new, status: :unprocessable_entity
    end
  end

  # Manual entry for when a share text isn't available.
  def manual
    attrs = params.expect(result: %i[ game played_on solved score_value breakdown minutes seconds q1 q2 q3 q4 ])
    @manual = current_user.results.find_or_initialize_by(game: attrs[:game], played_on: parse_date(attrs[:played_on]))
    @manual.assign_attributes(manual_attributes(attrs))

    if @manual.save
      redirect_to after_save_path, notice: "Saved #{@manual.game_definition.name} #{@manual.summary} (+#{format_points(@manual.points)})"
    else
      @played_on = @manual.played_on || Date.current
      @manual_failed = true
      flash.now[:alert] = @manual.errors.full_messages.to_sentence
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    current_user.results.find(params[:id]).destroy
    redirect_to results_path, notice: "Score deleted.", status: :see_other
  end

  private
    def parse_date(value)
      date = Date.parse(value.to_s)
      date > Date.current ? Date.current : date
    rescue Date::Error
      Date.current
    end

    def after_save_path
      params[:return_to].to_s.start_with?("/") && !params[:return_to].to_s.start_with?("//") ? params[:return_to] : root_path
    end

    def format_points(points) = helpers.number_with_precision(points, precision: 1, strip_insignificant_zeros: true)

    def manual_attributes(attrs)
      solved = attrs[:solved] == "1"
      case attrs[:game]
      when "quordle"
        words = [ attrs[:q1], attrs[:q2], attrs[:q3], attrs[:q4] ].map { |w| w.to_s.strip.upcase.presence || "X" }
        { solved: words.exclude?("X"), breakdown: words.join(","), score_value: words.sum { |w| w == "X" ? 13 : w.to_i } }
      when "connections"
        solved ? { solved: true, score_value: attrs[:score_value].to_i, breakdown: "4" }
               : { solved: false, score_value: 4, breakdown: attrs[:breakdown].to_s }
      when "one_word_search"
        { solved: solved, score_value: solved ? attrs[:minutes].to_i * 60 + attrs[:seconds].to_i : nil }
      else
        { solved: solved, score_value: solved ? attrs[:score_value].presence&.to_i : nil }
      end.merge(share_text: nil, puzzle_number: nil)
    end
end
