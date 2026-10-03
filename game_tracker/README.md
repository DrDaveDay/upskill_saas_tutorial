# Puzzle Cup

A small web app where families or coworkers track their daily puzzle results,
compete on a monthly leaderboard, and play for a prize the group admin sets.

Supported games: **Wordle, Waffle, Quordle, Connections, One Word Search**.

## Entering scores: paste the Share text (not a screenshot)

Each game has a **Share** button that copies a short text summary, like
`Wordle 1,567 3/6` followed by the emoji grid. Pasting that text is the main way
to enter scores because:

* **It's accurate.** The score is written in the text (`3/6`, `#waffle807 4/5`,
  Quordle's 6️⃣5️⃣/🟥8️⃣, Connections' colored rows), so reading it is exact.
  Reading a screenshot with OCR is unreliable for emoji grids and depends on the phone's theme and layout.
* **It's fast on a phone.** Tap Share, open Puzzle Cup, tap *Paste from clipboard*, then Save.
  You can paste several games in one go.
* **It's private and simple.** No image uploads, storage, or OCR service needed.

If you don't have the share text, there's a **manual entry** tab for every game.
Entering a game again for the same day replaces the earlier score.

## Scoring (0–6 points per game per day)

| Game | Points |
| --- | --- |
| Wordle | 1 guess = 6 … 6 guesses = 1, miss = 0 |
| Waffle | stars + 1 (5★ = 6), fail = 0 |
| Quordle | average over the 4 words: solved by guess 4 = 6 … guess 9 = 1, missed = 0 |
| Connections | perfect = 6, −1 per mistake; fail = ½ point per group found |
| One Word Search | ≤30s = 6, ≤1m = 5, ≤1½m = 4, ≤2m = 3, ≤3m = 2, slower = 1 |

The monthly leaderboard ranks by total points. Ties go to whoever played fewer games.
Each game is capped at the same score so no single game dominates.
Scoring rules live in `app/models/game.rb`, and share-text parsing in `app/models/share_parser.rb`.

## Groups, admins and prizes

* Anyone can sign up and create a group. The creator becomes its **admin**.
* Admins share an **invite link** (`/join/CODE`). New people sign up through it and land in the group.
  Admins can regenerate the link, promote or remove members, and rename the group.
* Admins set the **prize** for this month and next. It's shown in a banner at the top of the leaderboard,
  along with who is currently leading. Past months show the final standings and the winner.
* One score counts in every group you belong to, so family and office groups share the same entries.

## Running locally

Requires Ruby 3.3+.

```sh
cd game_tracker
bundle install
bin/rails db:setup        # creates the DB and loads demo data
bin/rails server
```

Then open http://localhost:3000. Demo login: `alice@example.com` / `password123`.

Set `TIME_ZONE` (default `Eastern Time (US & Canada)`) to control when "today" rolls over.

Run the tests with `bin/rails test`.
