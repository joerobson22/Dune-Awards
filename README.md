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
| 2 | *Part one: The players* | |
| 3 | **Favourite alliances**: a column each for Emperor, Spacing Guild, Bene Gesserit, Fremen | One alliance per click |
| 4 | **Silly awards**: most 4th places, most 3rd places, lowest VP finish | One award per click |
| 5 | **Muad'Dib**: a point for leading each core stat | One stat per click, then the award card |
| 6 | **Leader Award**: a point for the best win rate with each base leader | One leader per click, then the award card |
| 7 | **Loyal to the end**: **Na-Baron** (most wins as the Baron) and **Prince of Ix** (best win rate as Rhombur) | One award per click |
| 8 | *Part two: The long war* | |
| 9 | **Lisan Al-Gaib**, with **Points the Way** and **Chaumurky** | 1: play all 53 games live. 2–4: one award card each |
| 10 | **Shai Hulud**, with **Treachery** | 1: play all games live. 2–3: one award card each |
| 11 | *Part three: The four boxes* | |
| 12–15 | **Duke of Arrakis**, **Leader of IX**, **Tleilax Master**, **Imperium Lord** | 4th, 3rd, 2nd, then 1st place, one per click |
| 16 | The spice must flow: every winner on one screen | |

**Favourite alliances (slide 3).** Each column fills with the players whose favourite it
was, from the "Fave Alliance" row of `core_stats.csv`. An alliance nobody picked says "No one".
- The emblems are drawn by the program. The game's own art can't go in a public repo.
- To use real icons, drop `emperor.png`, `spacing_guild.png`, `bene_gesserit.png` and
  `fremen.png` into `assets/alliances/`. Square PNGs with transparency look best.

**Silly awards (slide 4).** Each panel lists all four players, with the "winner" lit gold.
Lowest VP finish names the leader and game number under each score.

**Muad'Dib (slide 5).** Every number in `core_stats.csv` becomes a tile. Each click names
that stat's leader and gives them a point in the table. Ties give everyone tied a point.
Highest wins by default. Swordmaster and High Council rounds go to the lowest number,
because getting them earlier is better. Section 4 shows how to change this.

**Leader Award (slide 6).** A row per leader: Baron, Rabban, Paul, Leto, Ariana, Memnon,
Ilban. Each cell is a player's win rate with that leader.
- Each click reveals a leader. The best rate is lit gold and scores a point.
- Level rates go to the player with more wins, then share the point.
- A leader nobody has won with (Ilban, so far) scores no point.
- Most points takes the Leader Award.

**Loyal to the end (slide 7).** Two honours for sticking with one leader. Na-Baron counts
wins as the Baron; level counts go to whoever played him fewer times.

**The live wins chart (slide 9).** A line per player grows game by game. The leaderboard
beside it re-sorts as the lead changes.
- A win that extends a streak flashes **gold**, labelled "3 IN A ROW".
- A tie-breaker win flashes the colour of the method: **spice** orange, **solari** silver,
  **water** blue, **Chaumurky** purple. These match the cell colours in the spreadsheet.
- The Tie-breaks column keeps a coloured dot for each one.

**The live VP chart (slide 10).** Running total VPs per player. Each new single-game record
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

### `data/players.csv`: names, people and colours

```
player,display_name,person,colour
HedgeKnight,HedgeKnight,Dad,#D9483B
```

- `display_name` is shown on screen. Change it (e.g. `Grandalf` → `Grandad`) without
  touching the game history.
- `person` links the tag to the name used in `core_stats.csv`.
- `colour` is the player's line and accent colour. Tonight: HedgeKnight red, Donaldthefrog
  green, Grandalf blue, LoomingGoblin yellow.

### `data/core_stats.csv`: one row per person per stat

```
person,group,stat,value
Joe,Core,Avg. Conflicts won,2.84
Joe,Core,Fave Alliance,Fremen
```

The app's averages from the spreadsheet. `group` is shown above each Muad'Dib tile
(`Core`, `IX`, `Immortality`, `Uprising`). Every `person` must appear in `players.csv`.
- A new stat row appears on the Muad'Dib slide automatically.
- Write numbers without a `%` sign. Stats whose name starts with `%` show one on screen.
- Text values (like `Fave Alliance`) are skipped by Muad'Dib.

---

## 4. Adding a new award

All slides are listed, in order, in **`scripts/awards.gd`**. That is the only file you edit to
add, remove or reorder a slide. There are three ways to add one, easiest first.

### A. A top-4 reveal: one entry, no new file

Paste this into the list in `scripts/awards.gd`, where it says *Add new award slides here*:

```gdscript
RankingRevealSlide.new({
    "eyebrow": "House Atreides",
    "title": "The Kwisatz Haderach",
    "subtitle": "Most games played as Paul",
    "values": data.leader_plays("Paul"),    # player -> score
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
| `data.leader_wins("Paul")` | Games won as a leader |
| `data.finishes(4)` | Times finishing in a given place (4 = last) |

Two more return a record per player, not a single number:
- `data.leader_record("Paul")`: player → `{plays, wins}`.
- `data.lowest_game_of("Grandalf")`: `{vp, leader, game}` for that player's worst game.

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
- `build()` runs again whenever the slide is shown, e.g. after going back. Keep what it
  makes in vars starting with `_`: lists, maps and node links there are emptied first.

### C. A live race chart

To tell a new story game by game, extend `RaceSlide` the way `wins_race_slide.gd` and
`vp_race_slide.gd` do. You fill in the chart values, the leaderboard columns, and
`apply_game()`, which runs as each game is reached. Call `chart.flash(...)` and
`table.flash_cell(...)` there for highlights.

### D. The new multi-award slides

These take their settings in `awards.gd`, so most changes need no new file.

**`HonoursSlide.new([...], {heading})`**: two to four award panels side by side. The silly
awards and "Loyal to the end" both use it. Each entry:
```gdscript
{"eyebrow": "Fed to the worm", "title": "Most 4th places",
    "values": data.finishes(4), "unit": "4th place"},
```
The heading is `{"eyebrow": ..., "title": ..., "subtitle": ...}`. Optional entry keys:
- `"lowest_wins": true` when the smallest number wins.
- `"tiebreak"`: a second score that splits level players.
- `"detail": func(p): ...` for a line under each name.
- `"format": func(v): ...` to show the number differently, e.g. as a percentage.
- `"summary": func(p): ...` for the line on the finale card.

**`CoreStatsSlide.new({...})`**: the Muad'Dib slide.
- `"labels"`: stat name in the CSV → name on screen, e.g. `"Avg. SMF": "Spice Must Flow"`.
- `"lower_wins"`: stat names where the lowest value earns the point.
- `"skip"`: stat names to leave out.

**`LeaderAwardsSlide.new(["Baron", "Rabban", ...])`**: the Leader Award table. List any
leaders from `games.csv`; up to about eight rows fit.

**`FaveAllianceSlide.new()`**: reads the alliances from `ALLIANCES` in `config.gd`.

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
  players.csv                 ← display names, people and colours
  core_stats.csv              ← the app's averages: Muad'Dib and alliances
assets/alliances/             optional alliance icons (see section 2)
scripts/
  awards.gd                   ★ the running order: add awards here
  config.gd                   ★ colours, fonts, timings, file paths
  game_data.gd                loads the CSVs; all the stats functions
  main.gd                     the show: input, slide changes, footer
  slides/
    slide.gd                  base class every slide extends
    title_slide.gd            opening title
    section_slide.gd          "Part one / Part two" dividers
    fave_alliance_slide.gd    favourite alliances, one column each
    honours_slide.gd          side-by-side honours: silly awards, Loyal to the end
    core_stats_slide.gd       Muad'Dib: a point per core stat
    leader_awards_slide.gd    Leader Award: a point per leader
    race_slide.gd             shared layout for the live chart slides
    wins_race_slide.gd        Lisan Al-Gaib, Points the Way, Chaumurky
    vp_race_slide.gd          Shai Hulud, Treachery
    ranking_reveal_slide.gd   reusable 4th-to-1st reveal
    finale_slide.gd           all winners
    example_custom_slide.gd   template for a slide of your own (not in the show)
  ui/                         building blocks: chart, leaderboard, award card,
                              alliance emblems, gold sparks, desert background, fonts
fonts/                        Michroma, Cormorant Garamond, Cinzel (SIL Open Font Licence)
```

---

## 7. If something goes wrong

- **"The ceremony could not start"**: the message names the CSV line at fault. Usually a
  `game` or `vp` cell is not a whole number.
- **A player appears twice, or with an unexpected colour**: their tag in `games.csv` does
  not exactly match `players.csv` (check capitals and spaces).
- **"core_stats.csv: … has no matching player"**: add that name to the `person` column of
  `players.csv`.
- **Editing the CSV in Excel**: save as *CSV UTF-8*. Keep the header row as it is.
