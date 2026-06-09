
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
  if (is.null(f) || is.na(f)) "\u26BD" else unname(f)
}

# ── Password hashing ──────────────────────────────────────────────────────────
hash_password <- function(pw) digest::digest(pw, algo = "sha256")

# ── Read helpers ──────────────────────────────────────────────────────────────
read_matches <- function() {
  tryCatch({
    df <- wb_to_df(DATA_PATH, sheet = "matches", col_names = TRUE)
    if (nrow(df) == 0) return(make_empty_matches())
    df
  }, error = function(e) { warning("read_matches: ", e$message); make_empty_matches() })
}

make_empty_matches <- function() {
  data.frame(match_id=character(), round=character(), date=character(),
             team1=character(), team2=character(), venue=character(),
             stringsAsFactors=FALSE)
}

read_votes <- function() {
  tryCatch({
    df <- wb_to_df(DATA_PATH, sheet = "votes", col_names = TRUE)
    if (nrow(df) == 0) return(empty_votes())
    df
  }, error = function(e) { warning("read_votes: ", e$message); empty_votes() })
}

empty_votes <- function()
  data.frame(vote_id=character(), player=character(), match_id=character(),
             pick=character(), timestamp=character(), stringsAsFactors=FALSE)

read_results <- function() {
  tryCatch({
    df <- wb_to_df(DATA_PATH, sheet = "results", col_names = TRUE)
    if (nrow(df) == 0) return(empty_results())
    df
  }, error = function(e) { warning("read_results: ", e$message); empty_results() })
}

empty_results <- function()
  data.frame(match_id=character(), winner=character(), score=character(),
             stringsAsFactors=FALSE)

read_users <- function() {
  tryCatch({
    df <- wb_to_df(DATA_PATH, sheet = "users", col_names = TRUE)
    if (nrow(df) == 0) return(empty_users())
    df
  }, error = function(e) { warning("read_users: ", e$message); empty_users() })
}

empty_users <- function()
  data.frame(username=character(), pw_hash=character(), created=character(),
             stringsAsFactors=FALSE)

# ── Write helpers ─────────────────────────────────────────────────────────────
save_vote <- function(player, match_id, pick) {
  wb    <- wb_load(DATA_PATH)
  votes <- tryCatch(wb_to_df(wb, sheet = "votes", col_names = TRUE),
                    error = function(e) empty_votes())
  if (nrow(votes) == 0) votes <- empty_votes()
  votes <- votes[!(votes$player == player & votes$match_id == match_id), ]
  votes <- rbind(votes, data.frame(
    vote_id   = paste0(player, "_", match_id, "_", format(Sys.time(), "%Y%m%d%H%M%S")),
    player    = player, match_id = match_id, pick = pick,
    timestamp = format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
    stringsAsFactors = FALSE
  ))
  wb$remove_worksheet("votes"); wb$add_worksheet("votes")
  wb$add_data(sheet = "votes", x = votes, start_row = 1)
  wb$save(DATA_PATH)
  invisible(TRUE)
}

save_result <- function(match_id, winner, score) {
  wb      <- wb_load(DATA_PATH)
  results <- tryCatch(wb_to_df(wb, sheet = "results", col_names = TRUE),
                      error = function(e) empty_results())
  if (nrow(results) == 0) results <- empty_results()
  results <- results[results$match_id != match_id, ]
  results <- rbind(results, data.frame(match_id=match_id, winner=winner,
                                       score=score, stringsAsFactors=FALSE))
  wb$remove_worksheet("results"); wb$add_worksheet("results")
  wb$add_data(sheet = "results", x = results, start_row = 1)
  wb$save(DATA_PATH)
  invisible(TRUE)
}

# Register new user — returns list(ok, message)
register_user <- function(username, password) {
  username <- trimws(username)
  if (nchar(username) < 2)
    return(list(ok=FALSE, message="Username must be at least 2 characters."))
  if (nchar(password) < 4)
    return(list(ok=FALSE, message="Password must be at least 4 characters."))
  if (grepl("[^A-Za-z0-9_. -]", username))
    return(list(ok=FALSE, message="Username can only contain letters, numbers, spaces, _ . -"))
  
  users <- read_users()
  if (any(tolower(users$username) == tolower(username)))
    return(list(ok=FALSE, message="That username is already taken."))
  
  wb    <- wb_load(DATA_PATH)
  users <- rbind(users, data.frame(
    username = username,
    pw_hash  = hash_password(password),
    created  = format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
    stringsAsFactors = FALSE
  ))
  wb$remove_worksheet("users"); wb$add_worksheet("users")
  wb$add_data(sheet = "users", x = users, start_row = 1)
  wb$save(DATA_PATH)
  list(ok=TRUE, message=paste0("Account created! Welcome, ", username, "."))
}

# Verify login — returns list(ok, message)
verify_login <- function(username, password) {
  username <- trimws(username)
  users    <- read_users()
  if (nrow(users) == 0) return(list(ok=FALSE, message="No accounts found. Please register first."))
  row <- users[tolower(users$username) == tolower(username), ]
  if (nrow(row) == 0) return(list(ok=FALSE, message="Username not found."))
  if (row$pw_hash[1] != hash_password(password))
    return(list(ok=FALSE, message="Incorrect password."))
  list(ok=TRUE, message=paste0("Welcome back, ", row$username[1], "!"),
       username = row$username[1])
}

# ── Leaderboard ───────────────────────────────────────────────────────────────
compute_leaderboard <- function(votes, results) {
  if (nrow(votes) == 0 || nrow(results) == 0)
    return(data.frame(Rank=integer(), Player=character(), Points=integer(),
                      Correct=integer(), Total_Picks=integer(), stringsAsFactors=FALSE))
  votes %>%
    inner_join(results, by = "match_id") %>%
    mutate(correct = (pick == winner)) %>%
    group_by(player) %>%
    summarise(Points=sum(correct,na.rm=TRUE), Correct=sum(correct,na.rm=TRUE),
              Total_Picks=n(), .groups="drop") %>%
    arrange(desc(Points), desc(Total_Picks)) %>%
    mutate(Rank = row_number()) %>%
    rename(Player = player) %>%
    select(Rank, Player, Points, Correct, Total_Picks)
}

# ── Constants ─────────────────────────────────────────────────────────────────
GROUP_ROUNDS    <- paste0("Group ", LETTERS[1:12])
KNOCKOUT_ROUNDS <- c("Round of 32","Round of 16","Quarterfinal","Semifinal","Third Place","Final")
ROUNDS_ORDER    <- c(GROUP_ROUNDS, KNOCKOUT_ROUNDS)
ADMIN_PASSWORD  <- "wc2026admin"

# ── Teams ─────────────────────────────────────────────────────────────────────
MAX_TEAMS_PER_USER <- 3

read_teams <- function() {
  tryCatch({
    df <- wb_to_df(DATA_PATH, sheet = "teams", col_names = TRUE)
    if (nrow(df) == 0) return(empty_teams())
    # ensure all cols are character
    df[] <- lapply(df, as.character)
    df
  }, error = function(e) { warning("read_teams: ", e$message); empty_teams() })
}

empty_teams <- function()
  data.frame(team_name=character(), username=character(), joined=character(),
             stringsAsFactors=FALSE)

# Create a new team and add the creator as the first member
# Returns list(ok, message)
create_team <- function(team_name, username) {
  team_name <- trimws(team_name)
  if (nchar(team_name) < 2)
    return(list(ok=FALSE, message="Team name must be at least 2 characters."))
  if (nchar(team_name) > 30)
    return(list(ok=FALSE, message="Team name must be 30 characters or fewer."))
  if (grepl("[^A-Za-z0-9 _.'!&-]", team_name))
    return(list(ok=FALSE, message="Team name contains invalid characters."))
  
  teams <- read_teams()
  
  # Check team name not already taken (case-insensitive)
  if (any(tolower(teams$team_name) == tolower(team_name)))
    return(list(ok=FALSE, message=paste0("A team called \"", team_name, "\" already exists.")))
  
  # Check user isn't already in MAX_TEAMS_PER_USER teams
  user_teams <- teams[teams$username == username, ]
  if (nrow(user_teams) >= MAX_TEAMS_PER_USER)
    return(list(ok=FALSE,
                message=paste0("You can only be in up to ", MAX_TEAMS_PER_USER, " teams.")))
  
  wb    <- wb_load(DATA_PATH)
  teams <- rbind(teams, data.frame(
    team_name = team_name, username = username,
    joined    = format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
    stringsAsFactors = FALSE
  ))
  wb$remove_worksheet("teams"); wb$add_worksheet("teams")
  wb$add_data(sheet = "teams", x = teams, start_row = 1)
  wb$save(DATA_PATH)
  list(ok=TRUE, message=paste0("Team \"", team_name, "\" created!"))
}

# Join an existing team
# Returns list(ok, message)
join_team <- function(team_name, username) {
  team_name <- trimws(team_name)
  teams     <- read_teams()
  
  existing  <- teams[tolower(teams$team_name) == tolower(team_name), ]
  if (nrow(existing) == 0)
    return(list(ok=FALSE, message=paste0("No team called \"", team_name, "\" found.")))
  
  canonical <- existing$team_name[1]   # use the canonical casing
  
  # Already a member?
  if (any(teams$username == username & tolower(teams$team_name) == tolower(team_name)))
    return(list(ok=FALSE, message=paste0("You are already in \"", canonical, "\".")))
  
  # Team limit
  user_teams <- teams[teams$username == username, ]
  if (nrow(user_teams) >= MAX_TEAMS_PER_USER)
    return(list(ok=FALSE,
                message=paste0("You can only be in up to ", MAX_TEAMS_PER_USER, " teams.")))
  
  wb    <- wb_load(DATA_PATH)
  teams <- rbind(teams, data.frame(
    team_name = canonical, username = username,
    joined    = format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
    stringsAsFactors = FALSE
  ))
  wb$remove_worksheet("teams"); wb$add_worksheet("teams")
  wb$add_data(sheet = "teams", x = teams, start_row = 1)
  wb$save(DATA_PATH)
  list(ok=TRUE, message=paste0("Joined team \"", canonical, "\"!"))
}

# Leave a team
leave_team <- function(team_name, username) {
  teams <- read_teams()
  new_teams <- teams[!(teams$username == username &
                         tolower(teams$team_name) == tolower(team_name)), ]
  wb <- wb_load(DATA_PATH)
  wb$remove_worksheet("teams"); wb$add_worksheet("teams")
  wb$add_data(sheet = "teams", x = new_teams, start_row = 1)
  wb$save(DATA_PATH)
  list(ok=TRUE, message=paste0("Left team \"", team_name, "\"."))
}

# Team leaderboard: sum each member's individual points, rank teams
compute_team_leaderboard <- function(votes, results, teams) {
  if (nrow(teams) == 0)
    return(data.frame(Rank=integer(), Team=character(), Members=integer(),
                      Total_Points=integer(), Avg_Points=numeric(),
                      stringsAsFactors=FALSE))
  
  ind <- compute_leaderboard(votes, results)   # individual scores
  
  if (nrow(ind) == 0) {
    # No scores yet — show teams with 0 pts
    teams %>%
      group_by(team_name) %>%
      summarise(Members=n(), .groups="drop") %>%
      mutate(Total_Points=0L, Avg_Points=0, Rank=row_number()) %>%
      rename(Team=team_name) %>%
      select(Rank, Team, Members, Total_Points, Avg_Points)
  } else {
    teams %>%
      left_join(ind %>% select(Player, Points), by = c("username"="Player")) %>%
      mutate(Points = ifelse(is.na(Points), 0L, Points)) %>%
      group_by(team_name) %>%
      summarise(
        Members      = n(),
        Total_Points = sum(Points, na.rm=TRUE),
        Avg_Points   = round(mean(Points, na.rm=TRUE), 2),
        .groups = "drop"
      ) %>%
      arrange(desc(Total_Points), desc(Avg_Points)) %>%
      mutate(Rank = row_number()) %>%
      rename(Team = team_name) %>%
      select(Rank, Team, Members, Total_Points, Avg_Points)
  }
}
