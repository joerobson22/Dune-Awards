# The Dune Awards

A click-through awards ceremony for our Dune: Imperium games, built in **Godot 4.6**.
It reads every game from a CSV file and builds the charts, leaderboards and reveals from it,
so adding a game or an award never means editing a slide by hand.

---

## 1. Run it

1. Install **Godot 4.6** (the standard build, not .NET) from godotengine.org.
2. Open Godot, click **Import**, and pick `project.godot` in this folder.
3. Press **F5** (or the ▶ button, top right).

The first open takes a few seconds while Godot imports the fonts.

### Controls

| Key or click | What it does |
|---|---|
| Left click, Space, →, Enter, Page Down | Next reveal, or the next slide |
| Right click, ←, Backspace, Page Up | Back one slide |
| Click while something is animating | Finish that animation at once |
| R | Replay the current slide from the start |
| Home | Back to the title |
| F11 or F | Full screen on or off |
| Esc | Leave full screen, then quit |

Presentation clickers send Page Up and Page Down, so they work too.

---

## 2. The running order

| # | Slide | Clicks |
|---|---|---|
| 1 | Title | |
| 2 | *Part one: The long war* | |
| 3 | **Lisan Al-Gaib**, with **Points the Way** and **Chaumurky** | 1: play all 53 games live. 2–4: one award card each |
| 4 | **Shai Hulud**, with **Treachery** | 1: play all games live. 2–3: one award card each |
| 5 | *Part two: The four boxes* | |
| 6–9 | **Duke of Arrakis**, **Leader of IX**, **Tleilax Master**, **Imperium Lord** | 4th, 3rd, 2nd, then 1st place, one per click |
| 10 | The spice must flow: every winner on one screen | |

**The live wins chart (slide 3).** A line per player grows game by game. The leaderboard
beside it re-sorts as the lead changes.
- A win that extends a streak flashes **gold**, labelled "3 IN A ROW".
- A tie-breaker win flashes the colour of the method: **spice** orange, **solari** silver,
  **water** blue, **Chaumurky** purple. These match the cell colours in the spreadsheet.
- The Tie-breaks column keeps a coloured dot for each one.

**The live VP chart (slide 4).** Running total VPs per player. Each new single-game record
flashes red: that is the Treachery race.

**Ties in an award.** Level scores are split by total VPs in the same scope. If players are
still level, they share the place and the card names both. The row says how a tie was
settled, e.g. "level on 3 wins, split by total VP: 88".

---

## 3. The data

### `data/games.csv`: one row per player per game

```
game,expansion,player,leader,vp,spice,solari,water,chaumurky,winner,win_method
3,Base,Donaldthefrog,Paul,10,3,13,,0,1,Solari
3,Base,HedgeKnight,Leto,9,,,,0,0,
```

| Column | Meaning |
|---|---|
| `game` | Game number. Games are shown in this order. |
| `expansion` | `Base`, `IX`, `Immortality` or `Uprising`. New codes are added in `scripts/config.gd`. |
| `player` | The player tag. It must match `data/players.csv`. |
| `leader` | Leader played. |
| `vp` | Victory points. |
| `spice`, `solari`, `water` | Only needed when they decided a tie. Leave blank otherwise. |
| `chaumurky` | `1` if the player held Chaumurky (wins a tie on VPs). |
| `winner` | `1` for the winner. **Optional**: see below. |
| `win_method` | `VP`, `Spice`, `Solari`, `Water` or `Chaumurky`. **Optional.** |

**Adding a new game:** add four rows with the next game number. You may leave `winner` and
`win_method` blank. The program then works the winner out the same way the game does: most
VPs, then Chaumurky, then spice, solari, water. That rule was checked against all 53 games in
the spreadsheet and agrees with every one.

### `data/players.csv`: names and colours

```
player,display_name,colour
HedgeKnight,HedgeKnight,#5FB37F
```

Change `display_name` to show a real name on screen (for example `Grandalf` → `Grandad`)
without touching the game history. `colour` is the player's line and accent colour.

### `data/core_stats.csv`

The app's top-level averages from the spreadsheet (conflicts won, SMF, favourite alliance,
and so on), kept for completeness. No slide uses them yet. Section 4 shows how to add one.

---

## 4. Adding a new award

All slides are listed, in order, in **`scripts/awards.gd`**. That is the only file you edit to
add, remove or reorder a slide. There are three ways to add one, easiest first.

### A. A top-4 reveal: one entry, no new file

Paste this into the list in `scripts/awards.gd`, where it says *Add new award slides here*:

```gdscript
RankingRevealSlide.new({
    "eyebrow": "The Harkonnen way",
    "title": "Na-Baron",
    "subtitle": "Most games played as the Baron",
    "values": data.leader_plays("Baron"),   # player -> score
    "unit": "game",                          # shown as "4 GAMES"
}),
```

Optional keys:
- `"tiebreak"`: a second score that splits level players, e.g. `data.total_vp()`.
- `"tiebreak_name"`: how that second score is named in the tie note, e.g. `"total VP"`.
- `"detail"`: a function that returns a small line under each name.
- `"show_top"`: how many places to reveal (default 4).

The award also appears on the finale slide automatically.

**Ready-made scores** (in `scripts/game_data.gd`). Each one takes an optional expansion code,
e.g. `data.wins("IX")`:

| Call | Score per player |
|---|---|
| `data.wins()` | Games won |
| `data.total_vp()` | Total victory points |
| `data.tiebreak_wins()` | Wins decided by a tie-break |
| `data.longest_streak()` | Longest run of consecutive wins |
| `data.best_single_game()` | Highest VPs in one game |
| `data.leader_plays("Paul")` | Games played as a leader |

**A score that is not on the list?** Add a function beside these in `game_data.gd`. Copy
`wins()` and change the counting line. It only has to return a Dictionary of player → number.

### B. An award with its own look

Copy `scripts/slides/example_custom_slide.gd`. It is a working example: a "Mentat" award with
bars that grow on a click, then the award card. Rename the class, change the parts marked ✎,
and add `YourSlideName.new(),` to the list in `awards.gd`.

Inside a slide:
- `add_header(eyebrow, title, subtitle)` draws the standard heading.
- `add_step(func)` queues something to happen on the next click.
- `play(tween, on_skip)` registers a long animation, so a click finishes it, not skips it.
- `add_award_card_steps(get_awards())` adds the gold winner cards.
- `get_awards()` returns what the finale lists.

### C. A live race chart

To tell a new story game by game, extend `RaceSlide` the way `wins_race_slide.gd` and
`vp_race_slide.gd` do. You fill in the chart values, the leaderboard columns, and
`apply_game()`, which runs as each game is reached. Call `chart.flash(...)` and
`table.flash_cell(...)` there for highlights.

### Section dividers

```gdscript
SectionSlide.new("Part three", "The leaders", "Who we trusted, and who betrayed us"),
```

---

## 5. Changing the look

Everything visual lives in **`scripts/config.gd`**:

- **Colours**: gold, sand, the tie-break colours, the record colour.
- **Timing**: `SECONDS_PER_GAME` sets how fast the live charts play (0.45 s per game ≈ 24 s).
- **Full screen at start**: `START_FULLSCREEN`.
- **Fonts**:
  - Michroma: the wide capitals, in the style of the films.
  - Cormorant Garamond: names and prose.
  - Cinzel: scores and Roman numerals, in the spirit of the card titles in the box.

**Want the films' own lettering?** Fan fonts such as *Dune Rise* are free for personal use.
Put the `.ttf` in `fonts/` and set `FONT_DISPLAY` to its path. Nothing else changes.

**Icon and boot splash.** `icon.png` and `boot_splash.png` are drawn from the same art as the
title slide. After changing colours or fonts, regenerate both so they still match:

```
godot --path . -s res://tools/render_branding.gd
```

The canvas is a fixed 1920 × 1080 and scales to any screen; other shapes get thin bars.

---

## 6. Project map

```
project.godot                 open this in Godot
icon.png, boot_splash.png     project icon and launch screen
tools/render_branding.gd      redraws the icon and splash from the title art
data/
  games.csv                   ← the history, one row per player per game
  players.csv                 ← display names and colours
  core_stats.csv              the app's averages (not yet on a slide)
scripts/
  awards.gd                   ★ the running order: add awards here
  config.gd                   ★ colours, fonts, timings, file paths
  game_data.gd                loads the CSVs; all the stats functions
  main.gd                     the show: input, slide changes, footer
  slides/
    slide.gd                  base class every slide extends
    title_slide.gd            opening title
    section_slide.gd          "Part one / Part two" dividers
    race_slide.gd             shared layout for the live chart slides
    wins_race_slide.gd        Lisan Al-Gaib, Points the Way, Chaumurky
    vp_race_slide.gd          Shai Hulud, Treachery
    ranking_reveal_slide.gd   reusable 4th-to-1st reveal
    finale_slide.gd           all winners
    example_custom_slide.gd   template for a slide of your own (not in the show)
  ui/                         building blocks: chart, leaderboard, award card,
                              gold sparks, desert background, fonts
fonts/                        Michroma, Cormorant Garamond, Cinzel (SIL Open Font Licence)
```

---

## 7. If something goes wrong

- **"The ceremony could not start"**: the message names the CSV line at fault. Usually a
  `game` or `vp` cell is not a whole number.
- **A player appears twice, or with an unexpected colour**: their tag in `games.csv` does
  not exactly match `players.csv` (check capitals and spaces).
- **Editing the CSV in Excel**: save as *CSV UTF-8*. Keep the header row as it is.
