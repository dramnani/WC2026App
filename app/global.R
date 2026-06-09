
library(shiny)
library(googlesheets4)
library(googledrive)
library(dplyr)
library(tidyr)
library(DT)
library(shinyjs)
library(bslib)
library(digest)

# ── Google Sheets auth ────────────────────────────────────────────────────────
# On Posit Connect Cloud: set env var GOOGLE_APPLICATION_CREDENTIALS to the
# path of your service-account JSON key (e.g. ".secrets/sa_key.json").
#
# Locally: if no key file is found, falls back to interactive browser OAuth
# (cached in .secrets/ so you only authenticate once).
#
.auth_gs4 <- function() {
  key_path <- Sys.getenv("GOOGLE_APPLICATION_CREDENTIALS",
                         unset = ".secrets/sa_key.json")
  if (file.exists(key_path)) {
    gs4_auth(path = key_path)
    drive_auth(path = key_path)
  } else {
    # Local interactive fallback — opens browser once, then caches token
    dir.create(".secrets", showWarnings = FALSE)
    options(gargle_oauth_cache = ".secrets")
    gs4_auth(
      email  = TRUE,
      cache  = ".secrets",
      scopes = "https://www.googleapis.com/auth/spreadsheets"
    )
  }
}

.auth_gs4()

# WC2026_SHEET_ID must be set as an environment variable.
# Locally: add  WC2026_SHEET_ID=<your-id>  to .Renviron (usethis::edit_r_environ())
# On Posit Connect: set it in the Content > Vars tab.
SHEET_ID <- Sys.getenv("WC2026_SHEET_ID")
if (!nzchar(SHEET_ID))
  stop(
    "WC2026_SHEET_ID is not set.\n",
    "  Locally:  add WC2026_SHEET_ID=<sheet-id> to your .Renviron\n",
    "  Connect:  set it in the Content > Vars tab"
  )

# ── Flag emoji lookup ─────────────────────────────────────────────────────────
FLAGS <- c(
  "Mexico"="🇲🇽","South Africa"="🇿🇦","South Korea"="🇰🇷","Czechia"="🇨🇿",
  "Canada"="🇨🇦","Bosnia and Herzegovina"="🇧🇦","Qatar"="🇶🇦","Switzerland"="🇨🇭",
  "Brazil"="🇧🇷","Morocco"="🇲🇦","Haiti"="🇭🇹","Scotland"="🏴󠁧󠁢󠁳󠁣󠁴󠁿",
  "United States"="🇺🇸","Paraguay"="🇵🇾","Australia"="🇦🇺","Türkiye"="🇹🇷",
  "Germany"="🇩🇪","Curaçao"="🇨🇼","Ivory Coast"="🇨🇮","Ecuador"="🇪🇨",
  "Netherlands"="🇳🇱","Japan"="🇯🇵","Sweden"="🇸🇪","Tunisia"="🇹🇳",
  "Belgium"="🇧🇪","Egypt"="🇪🇬","Iran"="🇮🇷","New Zealand"="🇳🇿",
  "Spain"="🇪🇸","Cape Verde"="🇨🇻","Saudi Arabia"="🇸🇦","Uruguay"="🇺🇾",
  "France"="🇫🇷","Senegal"="🇸🇳","Iraq"="🇮🇶","Norway"="🇳🇴",
  "Argentina"="🇦🇷","Algeria"="🇩🇿","Austria"="🇦🇹","Jordan"="🇯🇴",
  "Portugal"="🇵🇹","DR Congo"="🇨🇩","Uzbekistan"="🇺🇿","Colombia"="🇨🇴",
  "England"="🏴󠁧󠁢󠁥󠁮󠁧󠁿","Croatia"="🇭🇷","Ghana"="🇬🇭","Panama"="🇵🇦",
  "TBD"="⚽"
)

flag <- function(team) {
  f <- FLAGS[team]
  if (is.null(f) || is.na(f)) "\u26BD" else unname(f)
}

# ── Password hashing ──────────────────────────────────────────────────────────
hash_password <- function(pw) digest::digest(pw, algo = "sha256")

# ── Empty-frame constructors ──────────────────────────────────────────────────
make_empty_matches <- function()
  data.frame(match_id=character(), round=character(), date=character(),
             team1=character(), team2=character(), venue=character(),
             stringsAsFactors=FALSE)

empty_votes <- function()
  data.frame(vote_id=character(), player=character(), match_id=character(),
             pick=character(), timestamp=character(), stringsAsFactors=FALSE)

empty_results <- function()
  data.frame(match_id=character(), winner=character(), score=character(),
             stringsAsFactors=FALSE)

empty_users <- function()
  data.frame(username=character(), pw_hash=character(), created=character(),
             stringsAsFactors=FALSE)

empty_teams <- function()
  data.frame(team_name=character(), username=character(), joined=character(),
             stringsAsFactors=FALSE)

# ── Generic read helper ───────────────────────────────────────────────────────
# col_types = "c" forces every column to character, avoiding googlesheets4
# silently coercing numeric-looking IDs or dates.
.read_sheet_safe <- function(sheet_name, empty_fn) {
  tryCatch({
    df <- googlesheets4::read_sheet(SHEET_ID, sheet = sheet_name, col_types = "c")
    if (is.null(df) || nrow(df) == 0) return(empty_fn())
    df[] <- lapply(df, as.character)   # ensure no list-columns survive
    as.data.frame(df, stringsAsFactors = FALSE)
  }, error = function(e) {
    warning("read_sheet(", sheet_name, "): ", e$message)
    empty_fn()
  })
}

read_matches <- function() .read_sheet_safe("matches", make_empty_matches)
read_votes   <- function() .read_sheet_safe("votes",   empty_votes)
read_results <- function() .read_sheet_safe("results", empty_results)
read_users   <- function() .read_sheet_safe("users",   empty_users)
read_teams   <- function() .read_sheet_safe("teams",   empty_teams)

# ── Generic write helper ──────────────────────────────────────────────────────
# sheet_write() replaces the sheet contents atomically.
# Wraps in tryCatch so a transient API error returns a useful message rather
# than crashing the app.
.write_sheet_safe <- function(df, sheet_name) {
  tryCatch({
    googlesheets4::sheet_write(df, ss = SHEET_ID, sheet = sheet_name)
    invisible(TRUE)
  }, error = function(e) {
    stop("Failed to write to '", sheet_name, "': ", e$message)
  })
}

# ── Write helpers ─────────────────────────────────────────────────────────────
save_vote <- function(player, match_id, pick) {
  votes <- read_votes()
  if (nrow(votes) == 0) votes <- empty_votes()
  # Replace any existing pick for this player/match
  votes <- votes[!(votes$player == player & votes$match_id == match_id), ]
  votes <- rbind(votes, data.frame(
    vote_id   = paste0(player, "_", match_id, "_", format(Sys.time(), "%Y%m%d%H%M%S")),
    player    = player,
    match_id  = match_id,
    pick      = pick,
    timestamp = format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
    stringsAsFactors = FALSE
  ))
  .write_sheet_safe(votes, "votes")
}

save_result <- function(match_id, winner, score) {
  results <- read_results()
  if (nrow(results) == 0) results <- empty_results()
  results <- results[results$match_id != match_id, ]
  results <- rbind(results,
                   data.frame(match_id=match_id, winner=winner, score=score,
                              stringsAsFactors=FALSE))
  .write_sheet_safe(results, "results")
}

register_user <- function(username, password) {
  username <- trimws(username)
  if (nchar(username) < 2)
    return(list(ok=FALSE, message="Username must be at least 2 characters."))
  if (nchar(password) < 4)
    return(list(ok=FALSE, message="Password must be at least 4 characters."))
  if (grepl("[^A-Za-z0-9_. -]", username))
    return(list(ok=FALSE, message="Username may only contain letters, numbers, spaces, _ . -"))
  
  users <- read_users()
  if (nrow(users) > 0 && any(tolower(users$username) == tolower(username)))
    return(list(ok=FALSE, message="That username is already taken."))
  
  users <- rbind(users, data.frame(
    username = username,
    pw_hash  = hash_password(password),
    created  = format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
    stringsAsFactors = FALSE
  ))
  tryCatch({
    .write_sheet_safe(users, "users")
    list(ok=TRUE, message=paste0("Account created! Welcome, ", username, "."))
  }, error = function(e) {
    list(ok=FALSE, message=paste0("Registration failed: ", e$message))
  })
}

verify_login <- function(username, password) {
  username <- trimws(username)
  users    <- read_users()
  if (nrow(users) == 0)
    return(list(ok=FALSE, message="No accounts found. Please register first."))
  row <- users[tolower(users$username) == tolower(username), ]
  if (nrow(row) == 0) return(list(ok=FALSE, message="Username not found."))
  if (row$pw_hash[1] != hash_password(password))
    return(list(ok=FALSE, message="Incorrect password."))
  list(ok=TRUE, message=paste0("Welcome back, ", row$username[1], "!"),
       username = row$username[1])
}

create_team <- function(team_name, username) {
  team_name <- trimws(team_name)
  if (nchar(team_name) < 2)
    return(list(ok=FALSE, message="Team name must be at least 2 characters."))
  if (nchar(team_name) > 30)
    return(list(ok=FALSE, message="Team name must be 30 characters or fewer."))
  if (grepl("[^A-Za-z0-9 _.'!&-]", team_name))
    return(list(ok=FALSE, message="Team name contains invalid characters."))
  teams <- read_teams()
  if (nrow(teams) > 0 && any(tolower(teams$team_name) == tolower(team_name)))
    return(list(ok=FALSE, message=paste0("A team called \"", team_name, "\" already exists.")))
  user_teams <- if (nrow(teams) > 0) teams[teams$username == username, ] else empty_teams()
  if (nrow(user_teams) >= MAX_TEAMS_PER_USER)
    return(list(ok=FALSE, message=paste0("You can only be in up to ", MAX_TEAMS_PER_USER, " teams.")))
  teams <- rbind(teams, data.frame(
    team_name = team_name, username = username,
    joined    = format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
    stringsAsFactors = FALSE
  ))
  tryCatch({
    .write_sheet_safe(teams, "teams")
    list(ok=TRUE, message=paste0("Team \"", team_name, "\" created!"))
  }, error = function(e) list(ok=FALSE, message=e$message))
}

join_team <- function(team_name, username) {
  team_name <- trimws(team_name)
  teams     <- read_teams()
  existing  <- if (nrow(teams) > 0) teams[tolower(teams$team_name) == tolower(team_name), ]
  else empty_teams()
  if (nrow(existing) == 0)
    return(list(ok=FALSE, message=paste0("No team called \"", team_name, "\" found.")))
  canonical <- existing$team_name[1]
  if (any(teams$username == username & tolower(teams$team_name) == tolower(team_name)))
    return(list(ok=FALSE, message=paste0("You are already in \"", canonical, "\".")))
  user_teams <- teams[teams$username == username, ]
  if (nrow(user_teams) >= MAX_TEAMS_PER_USER)
    return(list(ok=FALSE, message=paste0("You can only be in up to ", MAX_TEAMS_PER_USER, " teams.")))
  teams <- rbind(teams, data.frame(
    team_name = canonical, username = username,
    joined    = format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
    stringsAsFactors = FALSE
  ))
  tryCatch({
    .write_sheet_safe(teams, "teams")
    list(ok=TRUE, message=paste0("Joined team \"", canonical, "\"!"))
  }, error = function(e) list(ok=FALSE, message=e$message))
}

leave_team <- function(team_name, username) {
  teams     <- read_teams()
  new_teams <- teams[!(teams$username == username &
                         tolower(teams$team_name) == tolower(team_name)), ]
  tryCatch({
    .write_sheet_safe(new_teams, "teams")
    list(ok=TRUE, message=paste0("Left team \"", team_name, "\"."))
  }, error = function(e) list(ok=FALSE, message=e$message))
}

# ── Leaderboard computations ──────────────────────────────────────────────────
compute_leaderboard <- function(votes, results) {
  if (nrow(votes) == 0 || nrow(results) == 0)
    return(data.frame(Rank=integer(), Player=character(), Points=integer(),
                      Correct=integer(), Total_Picks=integer(), stringsAsFactors=FALSE))
  votes %>%
    inner_join(results, by = "match_id") %>%
    mutate(correct = (pick == winner)) %>%
    group_by(player) %>%
    summarise(Points=sum(correct, na.rm=TRUE), Correct=sum(correct, na.rm=TRUE),
              Total_Picks=n(), .groups="drop") %>%
    arrange(desc(Points), desc(Total_Picks)) %>%
    mutate(Rank = row_number()) %>%
    rename(Player = player) %>%
    select(Rank, Player, Points, Correct, Total_Picks)
}

compute_team_leaderboard <- function(votes, results, teams) {
  if (nrow(teams) == 0)
    return(data.frame(Rank=integer(), Team=character(), Members=integer(),
                      Total_Points=integer(), Avg_Points=numeric(), stringsAsFactors=FALSE))
  ind <- compute_leaderboard(votes, results)
  if (nrow(ind) == 0) {
    teams %>%
      group_by(team_name) %>%
      summarise(Members=n(), .groups="drop") %>%
      mutate(Total_Points=0L, Avg_Points=0, Rank=row_number()) %>%
      rename(Team=team_name) %>%
      select(Rank, Team, Members, Total_Points, Avg_Points)
  } else {
    teams %>%
      left_join(ind %>% select(Player, Points), by = c("username"="Player")) %>%
      mutate(Points = ifelse(is.na(Points), 0L, as.integer(Points))) %>%
      group_by(team_name) %>%
      summarise(Members=n(), Total_Points=sum(Points, na.rm=TRUE),
                Avg_Points=round(mean(Points, na.rm=TRUE), 2), .groups="drop") %>%
      arrange(desc(Total_Points), desc(Avg_Points)) %>%
      mutate(Rank = row_number()) %>%
      rename(Team = team_name) %>%
      select(Rank, Team, Members, Total_Points, Avg_Points)
  }
}

# ── App-wide constants ────────────────────────────────────────────────────────
GROUP_ROUNDS       <- paste0("Group ", LETTERS[1:12])
KNOCKOUT_ROUNDS    <- c("Round of 32","Round of 16","Quarterfinal","Semifinal","Third Place","Final")
ROUNDS_ORDER       <- c(GROUP_ROUNDS, KNOCKOUT_ROUNDS)
ADMIN_PASSWORD     <- Sys.getenv("WC2026_ADMIN_PW", unset = "wc2026admin")
MAX_TEAMS_PER_USER <- 3
