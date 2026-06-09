library(tidyverse)
library(googlesheets4)
library(googledrive)
library(shiny)
library(here)
library(gargle)

# open browser and google account
# save/cache googlesheets credentials token within the app folder using gargle


library(googlesheets4)
library(googledrive)

KEY_PATH <- ".secrets/sa_key.json"

if (file.exists(KEY_PATH)) {
  gs4_auth(path = KEY_PATH)
  drive_auth(path = KEY_PATH)
} else {
  message("No service account key found at ", KEY_PATH,
          " — falling back to interactive OAuth.")
  dir.create(".secrets", showWarnings = FALSE)
  options(gargle_oauth_cache = ".secrets")
  gs4_auth(email = TRUE, cache = ".secrets",
           scopes = "https://www.googleapis.com/auth/spreadsheets")
  drive_auth(cache = ".secrets")
}

# ── Create or reuse the Sheet ─────────────────────────────────────────────────
existing <- tryCatch(drive_get("WC2026 Challenge"), error = function(e) NULL)

if (!is.null(existing) && nrow(existing) > 0) {
  ss <- as_id(existing$id[1])
  cat("Using existing sheet.\n")
  # Add any missing tabs
  current_sheets <- sheet_names(ss)
  for (sh in c("matches","votes","results","users","teams"))
    if (!sh %in% current_sheets) sheet_add(ss, sh)
} else {
  ss <- gs4_create("WC2026 Challenge",
                   sheets = c("matches","votes","results","users","teams"))
  cat("Created new sheet.\n")
}

sheet_id <- as.character(ss)
cat("\n\u2705 Sheet ID:\n", sheet_id, "\n\n")
cat("Add to .Renviron:  WC2026_SHEET_ID=", sheet_id, "\n\n")

# ── Match fixtures ────────────────────────────────────────────────────────────
matches <- data.frame(
  match_id = c(
    "A1","A2","A3","A4","A5","A6",
    "B1","B2","B3","B4","B5","B6",
    "C1","C2","C3","C4","C5","C6",
    "D1","D2","D3","D4","D5","D6",
    "E1","E2","E3","E4","E5","E6",
    "F1","F2","F3","F4","F5","F6",
    "G1","G2","G3","G4","G5","G6",
    "H1","H2","H3","H4","H5","H6",
    "I1","I2","I3","I4","I5","I6",
    "J1","J2","J3","J4","J5","J6",
    "K1","K2","K3","K4","K5","K6",
    "L1","L2","L3","L4","L5","L6",
    paste0("R32_", 1:16),
    paste0("R16_", 1:8),
    paste0("QF_",  1:4),
    paste0("SF_",  1:2),
    "3RD","FINAL"
  ),
  round = c(
    rep("Group A",6),  rep("Group B",6),  rep("Group C",6),  rep("Group D",6),
    rep("Group E",6),  rep("Group F",6),  rep("Group G",6),  rep("Group H",6),
    rep("Group I",6),  rep("Group J",6),  rep("Group K",6),  rep("Group L",6),
    rep("Round of 32",16), rep("Round of 16",8),
    rep("Quarterfinal",4), rep("Semifinal",2),
    "Third Place","Final"
  ),
  date = c(
    "2026-06-11","2026-06-11","2026-06-18","2026-06-18","2026-06-24","2026-06-24",
    "2026-06-12","2026-06-13","2026-06-18","2026-06-18","2026-06-24","2026-06-24",
    "2026-06-13","2026-06-13","2026-06-19","2026-06-19","2026-06-24","2026-06-24",
    "2026-06-12","2026-06-13","2026-06-19","2026-06-19","2026-06-25","2026-06-25",
    "2026-06-14","2026-06-14","2026-06-20","2026-06-20","2026-06-25","2026-06-25",
    "2026-06-14","2026-06-14","2026-06-20","2026-06-20","2026-06-25","2026-06-25",
    "2026-06-15","2026-06-15","2026-06-21","2026-06-21","2026-06-26","2026-06-26",
    "2026-06-15","2026-06-15","2026-06-21","2026-06-21","2026-06-26","2026-06-26",
    "2026-06-16","2026-06-16","2026-06-22","2026-06-22","2026-06-26","2026-06-26",
    "2026-06-16","2026-06-16","2026-06-22","2026-06-22","2026-06-27","2026-06-27",
    "2026-06-17","2026-06-17","2026-06-23","2026-06-23","2026-06-27","2026-06-27",
    "2026-06-17","2026-06-17","2026-06-23","2026-06-23","2026-06-27","2026-06-27",
    rep("2026-06-29",4),rep("2026-06-30",4),rep("2026-07-01",4),rep("2026-07-02",4),
    rep("2026-07-04",2),rep("2026-07-05",2),rep("2026-07-06",2),rep("2026-07-07",2),
    "2026-07-09","2026-07-10","2026-07-11","2026-07-12",
    "2026-07-14","2026-07-15",
    "2026-07-18","2026-07-19"
  ),
  team1 = c(
    "Mexico","South Korea","Czechia","Mexico","Czechia","South Africa",
    "Canada","Qatar","Switzerland","Canada","Switzerland","Bosnia and Herzegovina",
    "Brazil","Haiti","Scotland","Brazil","Scotland","Morocco",
    "United States","Australia","Türkiye","United States","Türkiye","Paraguay",
    "Germany","Ivory Coast","Germany","Ecuador","Curaçao","Ecuador",
    "Netherlands","Sweden","Netherlands","Tunisia","Japan","Tunisia",
    "Belgium","Iran","Belgium","New Zealand","Egypt","New Zealand",
    "Spain","Saudi Arabia","Spain","Uruguay","Cape Verde","Uruguay",
    "France","Iraq","France","Norway","Norway","Senegal",
    "Argentina","Austria","Argentina","Jordan","Argentina","Algeria",
    "Portugal","Uzbekistan","Portugal","Colombia","Colombia","DR Congo",
    "England","Ghana","England","Panama","Panama","Croatia",
    rep("TBD",16),rep("TBD",8),rep("TBD",4),rep("TBD",2),"TBD","TBD"
  ),
  team2 = c(
    "South Africa","Czechia","South Africa","South Korea","Mexico","South Korea",
    "Bosnia and Herzegovina","Switzerland","Bosnia and Herzegovina","Qatar","Canada","Qatar",
    "Morocco","Scotland","Morocco","Haiti","Brazil","Haiti",
    "Paraguay","Türkiye","Paraguay","Australia","United States","Australia",
    "Curaçao","Ecuador","Ivory Coast","Curaçao","Ivory Coast","Germany",
    "Japan","Tunisia","Sweden","Japan","Sweden","Netherlands",
    "Egypt","New Zealand","Iran","Egypt","Iran","Belgium",
    "Cape Verde","Uruguay","Saudi Arabia","Cape Verde","Saudi Arabia","Spain",
    "Senegal","Norway","Iraq","Senegal","France","Iraq",
    "Algeria","Jordan","Austria","Algeria","Jordan","Austria",
    "DR Congo","Colombia","Uzbekistan","DR Congo","Portugal","Uzbekistan",
    "Croatia","Panama","Ghana","Croatia","England","Ghana",
    rep("TBD",16),rep("TBD",8),rep("TBD",4),rep("TBD",2),"TBD","TBD"
  ),
  venue = c(
    "Estadio Azteca, Mexico City","Estadio Akron, Guadalajara",
    "Mercedes-Benz Stadium, Atlanta","Estadio Akron, Guadalajara",
    "Estadio Azteca, Mexico City","Estadio BBVA, Monterrey",
    "BMO Field, Toronto","Levi's Stadium, Santa Clara",
    "SoFi Stadium, Los Angeles","BC Place, Vancouver",
    "BC Place, Vancouver","Lumen Field, Seattle",
    "MetLife Stadium, New York/NJ","Gillette Stadium, Boston",
    "Gillette Stadium, Boston","Lincoln Financial Field, Philadelphia",
    "Hard Rock Stadium, Miami","Mercedes-Benz Stadium, Atlanta",
    "SoFi Stadium, Los Angeles","BC Place, Vancouver",
    "Levi's Stadium, Santa Clara","Lumen Field, Seattle",
    "SoFi Stadium, Los Angeles","Levi's Stadium, Santa Clara",
    "NRG Stadium, Houston","Lincoln Financial Field, Philadelphia",
    "BMO Field, Toronto","Arrowhead Stadium, Kansas City",
    "Lincoln Financial Field, Philadelphia","MetLife Stadium, New York/NJ",
    "AT&T Stadium, Dallas","Estadio BBVA, Monterrey",
    "NRG Stadium, Houston","Estadio BBVA, Monterrey",
    "AT&T Stadium, Dallas","Arrowhead Stadium, Kansas City",
    "Lumen Field, Seattle","SoFi Stadium, Los Angeles",
    "SoFi Stadium, Los Angeles","BC Place, Vancouver",
    "Lumen Field, Seattle","BC Place, Vancouver",
    "Mercedes-Benz Stadium, Atlanta","Hard Rock Stadium, Miami",
    "Mercedes-Benz Stadium, Atlanta","Hard Rock Stadium, Miami",
    "NRG Stadium, Houston","Estadio Akron, Guadalajara",
    "MetLife Stadium, New York/NJ","Gillette Stadium, Boston",
    "Lincoln Financial Field, Philadelphia","MetLife Stadium, New York/NJ",
    "MetLife Stadium, New York/NJ","Gillette Stadium, Boston",
    "Arrowhead Stadium, Kansas City","Levi's Stadium, Santa Clara",
    "AT&T Stadium, Dallas","Levi's Stadium, Santa Clara",
    "Arrowhead Stadium, Kansas City","Hard Rock Stadium, Miami",
    "NRG Stadium, Houston","Estadio Azteca, Mexico City",
    "Arrowhead Stadium, Kansas City","Hard Rock Stadium, Miami",
    "BC Place, Vancouver","Estadio Azteca, Mexico City",
    "AT&T Stadium, Dallas","BMO Field, Toronto",
    "MetLife Stadium, New York/NJ","Estadio BBVA, Monterrey",
    "Hard Rock Stadium, Miami","Mercedes-Benz Stadium, Atlanta",
    rep("TBD",16),rep("TBD",8),rep("TBD",4),rep("TBD",2),
    "TBD","MetLife Stadium, New York/NJ"
  ),
  stringsAsFactors = FALSE
)

edf <- function(...) data.frame(..., stringsAsFactors = FALSE)

sheet_write(matches, ss=ss, sheet="matches");      cat("✓ matches\n")
sheet_write(edf(vote_id=character(),player=character(),match_id=character(),
                pick=character(),timestamp=character()),
            ss=ss, sheet="votes");                 cat("✓ votes\n")
sheet_write(edf(match_id=character(),winner=character(),score=character()),
            ss=ss, sheet="results");               cat("✓ results\n")
sheet_write(edf(username=character(),pw_hash=character(),created=character()),
            ss=ss, sheet="users");                 cat("✓ users\n")
sheet_write(edf(team_name=character(),username=character(),joined=character()),
            ss=ss, sheet="teams");                 cat("✓ teams\n")

