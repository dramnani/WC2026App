# generate_manifest.R
# Creates manifest.json required by Posit Connect Cloud

# Install rsconnect if needed
if (!requireNamespace("rsconnect", quietly = TRUE)) {
  install.packages("rsconnect")
}

library(rsconnect)

# since app is within the "app" subfolder
app_dir <- "."


# Generate manifest.json
rsconnect::writeManifest(
  appDir      = app_dir,
  appFiles    = c("app.R", "global.R", "ui.R", "server.R"),
  appPrimaryDoc = "app.R"
)
