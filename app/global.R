
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

# ── Read data from Excel ──────────────────────────────────────────────────────
read_matches <- function() {
  wb_to_df(DATA_PATH, sheet = "matches", col_names = TRUE)
}

read_votes <- function() {
  df <- wb_to_df(DATA_PATH, sheet = "votes", col_names = TRUE)
  if (nrow(df) == 0) {
    data.frame(vote_id = character(), player = character(),
               match_id = character(), pick = character(),
               timestamp = character(), stringsAsFactors = FALSE)
  } else df
}

read_results <- function() {
  df <- wb_to_df(DATA_PATH, sheet = "results", col_names = TRUE)
  if (nrow(df) == 0) {
    data.frame(match_id = character(), winner = character(),
               score = character(), stringsAsFactors = FALSE)
  } else df
}

# ── Write a vote ──────────────────────────────────────────────────────────────
save_vote <- function(player, match_id, pick) {
  wb <- wb_load(DATA_PATH)
  votes <- wb_to_df(wb, sheet = "votes", col_names = TRUE)
  if (nrow(votes) == 0) {
    votes <- data.frame(vote_id = character(), player = character(),
                        match_id = character(), pick = character(),
                        timestamp = character(), stringsAsFactors = FALSE)
  }
  # Remove existing vote from this player for this match
  votes <- votes[!(votes$player == player & votes$match_id == match_id), ]
  # Append new vote
  new_row <- data.frame(
    vote_id   = paste0(player, "_", match_id, "_", format(Sys.time(), "%Y%m%d%H%M%S")),
    player    = player,
    match_id  = match_id,
    pick      = pick,
    timestamp = format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
    stringsAsFactors = FALSE
  )
  votes <- rbind(votes, new_row)
  wb$remove_worksheet("votes")
  wb$add_worksheet("votes")
  wb$add_data(sheet = "votes", x = votes, start_row = 1)
  wb$save(DATA_PATH)
  invisible(TRUE)
}

# ── Save result (admin) ───────────────────────────────────────────────────────
save_result <- function(match_id, winner, score) {
  wb <- wb_load(DATA_PATH)
  results <- wb_to_df(wb, sheet = "results", col_names = TRUE)
  if (nrow(results) == 0) {
    results <- data.frame(match_id = character(), winner = character(),
                          score = character(), stringsAsFactors = FALSE)
  }
  results <- results[results$match_id != match_id, ]
  results <- rbind(results, data.frame(match_id = match_id, winner = winner,
                                       score = score, stringsAsFactors = FALSE))
  wb$remove_worksheet("results")
  wb$add_worksheet("results")
  wb$add_data(sheet = "results", x = results, start_row = 1)
  wb$save(DATA_PATH)
  invisible(TRUE)
}

# ── Compute leaderboard ───────────────────────────────────────────────────────
compute_leaderboard <- function(votes, results) {
  if (nrow(votes) == 0 || nrow(results) == 0) {
    return(data.frame(Rank = integer(), Player = character(),
                      Points = integer(), Correct = integer(),
                      Total_Picks = integer(), stringsAsFactors = FALSE))
  }
  merged <- votes %>%
    inner_join(results, by = "match_id") %>%
    mutate(correct = (pick == winner))
  
  merged %>%
    group_by(player) %>%
    summarise(
      Points      = sum(correct, na.rm = TRUE),
      Correct     = sum(correct, na.rm = TRUE),
      Total_Picks = n(),
      .groups = "drop"
    ) %>%
    arrange(desc(Points), desc(Total_Picks)) %>%
    mutate(Rank = row_number()) %>%
    rename(Player = player) %>%
    select(Rank, Player, Points, Correct, Total_Picks)
}

# ── Round display order ───────────────────────────────────────────────────────
ROUNDS_ORDER <- c(
  "Group A","Group B","Group C","Group D","Group E","Group F",
  "Group G","Group H","Group I","Group J","Group K","Group L",
  "Round of 32","Round of 16","Quarterfinal","Semifinal","Third Place","Final"
)

GROUP_ROUNDS <- paste0("Group ", LETTERS[1:12])
KNOCKOUT_ROUNDS <- c("Round of 32","Round of 16","Quarterfinal","Semifinal","Third Place","Final")

ADMIN_PASSWORD <- "wc2026admin"   # Change before deploying!

