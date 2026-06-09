# app file
# can run locally or deploy
library(here)

source("global.R")
source("ui.R")
source("server.R")

shinyApp(ui = ui, server = server)