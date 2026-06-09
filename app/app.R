# app file
# can run locally or deploy
library(here)

source(here::here("app","global.R"))
source(here::here("app","ui.R"))
source(here::here("app","server.R"))

shinyApp(ui = ui, server = server)