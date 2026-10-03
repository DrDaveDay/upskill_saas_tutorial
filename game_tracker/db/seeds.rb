# Demo data: `bin/rails db:seed` then sign in as alice@example.com / password123
if User.exists?(email_address: "alice@example.com")
  puts "Seeds skipped: demo data already exists."
  return
end

people = %w[ Alice Bob Carol Dan ].map do |name|
  User.create!(name: "#{name} Demo", email_address: "#{name.downcase}@example.com", password: "password123")
end

group = Group.create_with_admin!(people.first, name: "The Demo Family")
people.drop(1).each { |user| group.memberships.create!(user: user) }
group.prizes.create!(month: Date.current, description: "Winner picks Friday's takeout 🍕")

random = Random.new(42)
(Date.current.beginning_of_month..Date.current).each do |day|
  people.each do |user|
    Game::KEYS.each do |game|
      next if random.rand < 0.25 # not everyone plays everything every day

      attrs = case game
      when "wordle" then { solved: random.rand > 0.05, score_value: random.rand(2..6) }
      when "waffle" then { solved: random.rand > 0.1, score_value: random.rand(0..5) }
      when "quordle" then { breakdown: Array.new(4) { random.rand < 0.08 ? "X" : random.rand(4..9) }.join(",") }
      when "connections"
        solved = random.rand > 0.2
        solved ? { solved: true, score_value: random.rand(0..3) } : { solved: false, score_value: 4, breakdown: random.rand(0..3).to_s }
      when "one_word_search" then { solved: random.rand > 0.05, score_value: random.rand(15..240) }
      end
      Result.record!(user: user, played_on: day, attributes: attrs.merge(game: game))
    end
  end
end

puts "Seeded #{User.count} users, #{Result.count} results. Sign in as alice@example.com / password123"
