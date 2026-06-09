
library(shiny)
library(openxlsx2)
library(dplyr)
library(tidyr)
library(DT)
library(shinyjs)
library(bslib)

DATA_PATH <- here::here("data", "votes.xlsx")

# flags for matches
FLAGS <- c(
  "Mexico" = "🇲🇽", "South Africa" = "🇿🇦", "South Korea" = "🇰🇷", "Czechia" = "🇨🇿",
  "Canada" = "🇨🇦", "Bosnia and Herzegovina" = "🇧🇦", "Qatar" = "🇶🇦", "Switzerland" = "🇨🇭",
  "Brazil" = "🇧🇷", "Morocco" = "🇲🇦", "Haiti" = "🇭🇹", "Scotland" = "🏴󠁧󠁢󠁳󠁣󠁴󠁿",
  "United States" = "🇺🇸", "Paraguay" = "🇵🇾", "Australia" = "🇦🇺", "Türkiye" = "🇹🇷",
  "Germany" = "🇩🇪", "Curaçao" = "🇨🇼", "Ivory Coast" = "🇨🇮", "Ecuador" = "🇪🇨",
  "Netherlands" = "🇳🇱", "Japan" = "🇯🇵", "Sweden" = "🇸🇪", "Tunisia" = "🇹🇳",
  "Belgium" = "🇧🇪", "Egypt" = "🇪🇬", "Iran" = "🇮🇷", "New Zealand" = "🇳🇿",
  "Spain" = "🇪🇸", "Cape Verde" = "🇨🇻", "Saudi Arabia" = "🇸🇦", "Uruguay" = "🇺🇾",
  "France" = "🇫🇷", "Senegal" = "🇸🇳", "Iraq" = "🇮🇶", "Norway" = "🇳🇴",
  "Argentina" = "🇦🇷", "Algeria" = "🇩🇿", "Austria" = "🇦🇹", "Jordan" = "🇯🇴",
  "Portugal" = "🇵🇹", "DR Congo" = "🇨🇩", "Uzbekistan" = "🇺🇿", "Colombia" = "🇨🇴",
  "England" = "🏴󠁧󠁢󠁥󠁮󠁧󠁿", "Croatia" = "🇭🇷", "Ghana" = "🇬🇭", "Panama" = "🇵🇦",
  "TBD" = "⚽"
)

flag <- function(team) {
  f <- FLAGS[team]
  if (is.na(f)) "⚽" else f
}

team_label <- function(team) {
  paste(flag(team), team)
}

# -----------------------------------------------------------------------------
# Empty table definitions
# -----------------------------------------------------------------------------

empty_matches <- function() {
  data.frame(
    match_id = character(),
    round    = character(),
    date     = character(),
    team1    = character(),
    team2    = character(),
    venue    = character(),
    stringsAsFactors = FALSE
  )
}

empty_votes <- function() {
  data.frame(
    vote_id   = character(),
    player    = character(),
    match_id  = character(),
    pick      = character(),
    timestamp = character(),
    stringsAsFactors = FALSE
  )
}

empty_results <- function() {
  data.frame(
    match_id = character(),
    winner   = character(),
    score    = character(),
    stringsAsFactors = FALSE
  )
}

empty_users <- function() {
  data.frame(
    username = character(),
    pw_hash  = character(),
    created  = character(),
    stringsAsFactors = FALSE
  )
}

empty_teams <- function() {
  data.frame(
    team_name = character(),
    username  = character(),
    joined    = character(),
    stringsAsFactors = FALSE
  )
}

read_sheet <- function(sheet, empty_df) {
  tryCatch({
    df <- wb_to_df(DATA_PATH, sheet = sheet, col_names = TRUE)

    if (nrow(df) == 0) {
      empty_df()
    } else {
      df
    }
    
  }, error = function(e) {
    warning(paste0("read_", sheet, ": ", e$message))
    empty_df()
  })
}

write_sheet <- function(sheet, data) {
  wb <- wb_load(DATA_PATH)
  
  if (sheet %in% names(wb)) {
    wb$remove_worksheet(sheet)
  }
  
  wb$add_worksheet(sheet)
  wb$add_data(sheet = sheet, x = data, start_row = 1)
  wb$save(DATA_PATH)
  
  invisible(TRUE)
}

read_matches <- function() read_sheet("matches", empty_matches)
read_votes   <- function() read_sheet("votes", empty_votes)
read_results <- function() read_sheet("results", empty_results)
read_users   <- function() read_sheet("users", empty_users)
read_teams   <- function() read_sheet("teams", empty_teams)

save_vote <- function(player, match_id, pick) {
  
  votes <- read_votes()
  
  votes <- votes[
    !(votes$player == player &
        votes$match_id == match_id),
  ]
  
  votes <- bind_rows(
    votes,
    data.frame(
      vote_id = paste0(
        player, "_", match_id, "_",
        format(Sys.time(), "%Y%m%d%H%M%S")
      ),
      player = player,
      match_id = match_id,
      pick = pick,
      timestamp = format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
      stringsAsFactors = FALSE
    )
  )
  
  write_sheet("votes", votes)
}

# -------------------------------
# save results
# ------------------------------
save_result <- function(match_id, winner, score) {
  
  results <- read_results()
  
  results <- results[results$match_id != match_id, ]
  
  results <- bind_rows(
    results,
    data.frame(
      match_id = match_id,
      winner   = winner,
      score    = score,
      stringsAsFactors = FALSE
    )
  )
  
  write_sheet("results", results)
}

#-------------------------------
# Constants
# -----------------------------
GROUP_ROUNDS <- paste0("Group ", LETTERS[1:12])

KNOCKOUT_ROUNDS <- c(
  "Round of 32",
  "Round of 16",
  "Quarterfinal",
  "Semifinal",
  "Third Place",
  "Final"
)

ROUNDS_ORDER <- c(
  GROUP_ROUNDS,
  KNOCKOUT_ROUNDS
)

MAX_TEAMS_PER_USER <- 3
ADMIN_PASSWORD <- Sys.getenv("WC2026_ADMIN_PASSWORD")

# ------------------------------
# Leaderboard
# ------------------------------
compute_leaderboard <- function(votes, results) {
  
  if (nrow(votes) == 0 || nrow(results) == 0) {
    return(
      data.frame(
        Rank = integer(),
        Player = character(),
        Points = integer(),
        Correct = integer(),
        Total_Picks = integer(),
        stringsAsFactors = FALSE
      )
    )
  }
  
  votes %>%
    inner_join(results, by = "match_id") %>%
    mutate(correct = pick == winner) %>%
    group_by(player) %>%
    summarise(
      Points = sum(correct),
      Correct = sum(correct),
      Total_Picks = n(),
      .groups = "drop"
    ) %>%
    arrange(desc(Points), desc(Total_Picks)) %>%
    mutate(Rank = row_number()) %>%
    rename(Player = player) %>%
    select(Rank, Player, Points, Correct, Total_Picks)
}