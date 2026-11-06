class_name Config
extends RefCounted
## ════════════════════════════════════════════════════════════════════
##  SETTINGS — data files, timings, colours and fonts in one place.
##  Change a value here and every slide picks it up.
##  (The running order of the awards lives in scripts/awards.gd.)
## ════════════════════════════════════════════════════════════════════


# ── Data files ───────────────────────────────────────────────────────
## One row per player per game. See README.md for the column format.
const GAMES_CSV := "res://data/games.csv"
## Display name and line colour for each player tag.
const PLAYERS_CSV := "res://data/players.csv"
## The app's per-person stats (Muad'Dib award, favourite alliances).
const CORE_STATS_CSV := "res://data/core_stats.csv"

## Expansion codes used in games.csv, in the order they were played,
## mapped to the name shown on screen. Add a new line for a new box.
const EXPANSIONS := {
	"Base": "Dune: Imperium",
	"IX": "Rise of Ix",
	"Immortality": "Immortality",
	"Uprising": "Uprising",
}

## Tie-break order used when a game in games.csv has no winner marked.
## (Chaumurky always wins a tie on VPs if the tied player holds it.)
const TIEBREAK_ORDER := ["spice", "solari", "water"]


# ── Presentation ─────────────────────────────────────────────────────
## Seconds each game takes in the live "race" graphs.
const SECONDS_PER_GAME := 0.45
## Cross-fade between slides, in seconds.
const SLIDE_FADE := 0.55
## Start the show full screen (F11 toggles it at any time).
const START_FULLSCREEN := false


# ── Colours ──────────────────────────────────────────────────────────
const NIGHT := Color("0a0705")          # page background
const INK := Color("140d08")            # panels
const GOLD := Color("c9a14a")           # rules, borders, accents
const GOLD_BRIGHT := Color("f2d98d")    # highlights, streak flash
const GOLD_DEEP := Color("8a6526")
const SAND := Color("eadbb8")           # primary text
const SAND_DIM := Color("a8977a")       # secondary text
const SAND_FAINT := Color("6b5d49")     # tertiary text, gridlines

## Flash colours for how a game was won. Mirrors the spreadsheet fills.
const METHOD_COLOURS := {
	"VP": Color("f2d98d"),
	"Spice": Color("ff9a2e"),
	"Solari": Color("d4dbe2"),
	"Water": Color("3fc8f2"),
	"Chaumurky": Color("b86ce6"),
}
## The four alliances, in reveal order. "key" names the optional icon
## file: put res://assets/alliances/<key>.png in place to use your own
## artwork instead of the drawn emblem. "colour" tints that column.
const ALLIANCES := [
	{"name": "Emperor", "key": "emperor", "colour": Color("b8423a")},
	{"name": "Spacing Guild", "key": "spacing_guild", "colour": Color("d9822b")},
	{"name": "Bene Gesserit", "key": "bene_gesserit", "colour": Color("9b5fc0")},
	{"name": "Fremen", "key": "fremen", "colour": Color("3f8fc9")},
]
const STREAK_COLOUR := Color("f2d98d")
const RECORD_COLOUR := Color("e5483a")  # Treachery: a new single-game record


# ── Fonts ────────────────────────────────────────────────────────────
## Display face: wide, geometric capitals in the style of the films.
## Want the film's own lettering? Drop a font such as "Dune Rise" into
## /fonts and point FONT_DISPLAY at it.
const FONT_DISPLAY := "res://fonts/Michroma-Regular.ttf"
## Serif for names, numbers and prose: the luxury half of the look.
const FONT_SERIF := "res://fonts/CormorantGaramond-Variable.ttf"
const FONT_SERIF_ITALIC := "res://fonts/CormorantGaramond-Italic-Variable.ttf"
## Roman capitals for scores and numerals, like the cards in the box.
const FONT_NUMBERS := "res://fonts/Cinzel-Variable.ttf"
