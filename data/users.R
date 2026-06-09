# users and teams in the data

library(openxlsx2)
library(here)

path <- here("data", "votes.xlsx")
wb   <- wb_load(path)
sheets <- wb_get_sheet_names(wb)
cat("Current sheets:", paste(sheets, collapse=", "), "\n")

if (!"users" %in% sheets) {
  wb$add_worksheet("users")
  wb$add_data(sheet = "users",
              x = data.frame(username=character(), pw_hash=character(),
                             created=character(), stringsAsFactors=FALSE),
              start_row = 1)
  cat("✓ 'users' sheet added\n")
} else { cat("'users' sheet already exists\n") }

if (!"teams" %in% sheets) {
  wb$add_worksheet("teams")
  wb$add_data(sheet = "teams",
              x = data.frame(team_name=character(), username=character(),
                             joined=character(), stringsAsFactors=FALSE),
              start_row = 1)
  cat("✓ 'teams' sheet added\n")
} else { cat("'teams' sheet already exists\n") }

wb$save(path)
cat("Saved to", path, "\n")
