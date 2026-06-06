# server


server <- function(input, output, session) {
  
  # ── Reactive state ──────────────────────────────────────────────────────────
  rv <- reactiveValues(
    player        = NULL,
    admin_ok      = FALSE,
    data_version  = 0    # increment to trigger re-reads after writes
  )
  
  autoInvalidate <- reactiveTimer(30000)   # refresh every 30 s
  
  # ── Reactive data ───────────────────────────────────────────────────────────
  r_matches <- reactive({
    rv$data_version
    read_matches()
  })
  
  r_votes <- reactive({
    rv$data_version
    autoInvalidate()
    read_votes()
  })
  
  r_results <- reactive({
    rv$data_version
    autoInvalidate()
    read_results()
  })
  
  my_picks <- reactive({
    req(rv$player)
    votes <- r_votes()
    mine  <- votes[votes$player == rv$player, ]
    if (nrow(mine) == 0) return(setNames(character(0), character(0)))
    setNames(mine$pick, mine$match_id)
  })
  
  # ── Login ────────────────────────────────────────────────────────────────────
  output$user_logged_in <- reactive({ !is.null(rv$player) })
  outputOptions(output, "user_logged_in", suspendWhenHidden = FALSE)
  
  observeEvent(input$join_btn, {
    nm <- trimws(input$player_name_input)
    if (nchar(nm) < 1) {
      showNotification("Please enter a name.", type = "warning"); return()
    }
    rv$player <- nm
    showNotification(paste0("Welcome, ", nm, "! Start picking winners."),
                     type = "message", duration = 3)
  })
  
  observeEvent(input$change_name_btn, {
    rv$player <- NULL
    updateTextInput(session, "player_name_input", value = "")
  })
  
  # ── Player bar ───────────────────────────────────────────────────────────────
  output$player_bar_ui <- renderUI({
    req(rv$player)
    lb  <- compute_leaderboard(r_votes(), r_results())
    row <- if (nrow(lb) > 0) lb[lb$Player == rv$player, ] else data.frame()
    pts    <- if (nrow(row) > 0) row$Points[1]      else 0L
    npicks <- if (nrow(row) > 0) row$Total_Picks[1] else 0L
    
    div(class = "player-bar",
        div(
          span(class = "player-name", paste0("👤 ", rv$player)),
          tags$span(style = "margin-left:1rem;", class = "player-score",
                    "Score: ", tags$strong(paste0(pts, " pts")),
                    tags$span(style = "margin-left:0.75rem;",
                              paste0(npicks, " pick", if (npicks != 1) "s" else "", " made"))
          )
        ),
        actionButton("change_name_btn", "Change name", class = "btn btn-sm btn-wc-gold")
    )
  })
  
  # ── Dynamic vote button observers ────────────────────────────────────────────
  # We store observers so we only create each one once
  vote_obs <- list()
  
  observe({
    all_inputs <- reactiveValuesToList(input)
    btn_names  <- names(all_inputs)[grepl("^vote_", names(all_inputs))]
    
    for (btn in btn_names) {
      if (!btn %in% names(vote_obs)) {
        local({
          b <- btn
          vote_obs[[b]] <<- observeEvent(input[[b]], {
            req(rv$player)
            # button name: vote_<match_id>_<safe_team>
            rest     <- sub("^vote_", "", b)
            # match_id is the first token (letters + digits only)
            match_id <- regmatches(rest, regexpr("^[A-Z0-9_]+?(?=_[^_])", rest, perl = TRUE))
            if (length(match_id) == 0) {
              # fallback: split on first underscore group that looks like a match id
              parts    <- strsplit(rest, "_", fixed = TRUE)[[1]]
              match_id <- parts[1]
              safe_team <- paste(parts[-1], collapse = "_")
            } else {
              safe_team <- sub(paste0("^", match_id, "_"), "", rest)
            }
            team <- gsub("_SPC_", " ", gsub("_DOT_", ".", safe_team))
            tryCatch({
              save_vote(rv$player, match_id, team)
              rv$data_version <- rv$data_version + 1
              showNotification(
                paste0("✓ Picked ", flag(team), " ", team),
                type = "message", duration = 2
              )
            }, error = function(e) {
              showNotification(paste("Save error:", e$message), type = "error")
            })
          }, ignoreInit = TRUE)
        })
      }
    }
  })
  
  # ── Match card renderer ──────────────────────────────────────────────────────
  make_match_card <- function(match_id, team1, team2, date_str, venue_str = NULL,
                              label = NULL) {
    picks_now   <- my_picks()
    results_now <- r_results()
    votes_now   <- r_votes()
    
    my_pick    <- picks_now[[match_id]]   # NULL if not voted
    result_row <- results_now[results_now$match_id == match_id, ]
    has_result <- nrow(result_row) > 0
    winner     <- if (has_result) result_row$winner[1] else NULL
    score_str  <- if (has_result) result_row$score[1]  else NULL
    
    mv   <- votes_now[votes_now$match_id == match_id, ]
    n1   <- sum(mv$pick == team1, na.rm = TRUE)
    n2   <- sum(mv$pick == team2, na.rm = TRUE)
    
    # Button IDs: spaces and dots encoded
    safe <- function(t) gsub("\\.", "_DOT_", gsub(" ", "_SPC_", t))
    id1  <- paste0("vote_", match_id, "_", safe(team1))
    id2  <- paste0("vote_", match_id, "_", safe(team2))
    
    # CSS classes for buttons
    cls_base <- "btn btn-sm team-vote-btn"
    cls1 <- cls_base; cls2 <- cls_base
    if (!is.null(my_pick) && !is.na(my_pick)) {
      if (my_pick == team1) cls1 <- paste(cls1, "selected")
      if (my_pick == team2) cls2 <- paste(cls2, "selected")
      if (has_result) {
        if (my_pick == team1)
          cls1 <- paste(cls1, if (winner == team1) "result-correct" else "result-wrong")
        if (my_pick == team2)
          cls2 <- paste(cls2, if (winner == team2) "result-correct" else "result-wrong")
      }
    }
    
    locked   <- is.null(rv$player) || has_result || team1 == "TBD" || team2 == "TBD"
    make_btn <- function(id, team, cls) {
      lbl <- tagList(span(class = "flag", flag(team)), br(), span(class = "tname", team))
      if (locked)
        div(class = cls, style = "cursor:default; pointer-events:none;", lbl)
      else
        actionButton(id, label = lbl, class = cls)
    }
    
    # Footer
    footer <- div(class = "match-footer",
                  if (has_result)
                    span(class = "result-score", paste0(score_str, "  ·  Winner: ", flag(winner), " ", winner)),
                  if (!is.null(my_pick) && !is.na(my_pick) && has_result) {
                    if (my_pick == winner) span(class = "correct-badge ms-1", " ✓ Correct!")
                    else span(class = "wrong-badge ms-1", paste0(" ✗ You picked ", my_pick))
                  } else if (!is.null(my_pick) && !is.na(my_pick) && !has_result) {
                    tags$small(style = "color:#7a8f7c;", paste0("Your pick: ", flag(my_pick), " ", my_pick))
                  },
                  br(),
                  tags$small(style = "color:#455045; font-size:0.65rem;",
                             paste0(n1 + n2, " total picks · ", team1, ": ", n1, " / ", team2, ": ", n2))
    )
    
    div(class = "match-card",
        if (!is.null(label)) div(class = "bracket-match-label", label),
        div(class = "match-date-label",
            if (!is.null(venue_str)) paste0(date_str, "  ·  ", venue_str) else date_str),
        div(class = "match-teams-row",
            make_btn(id1, team1, cls1),
            span(class = "vs-sep", "vs"),
            make_btn(id2, team2, cls2)
        ),
        footer
    )
  }
  
  # ── GROUP STAGE ──────────────────────────────────────────────────────────────
  output$groups_ui <- renderUI({
    matches <- r_matches()
    groups  <- LETTERS[1:12]
    
    group_divs <- lapply(groups, function(g) {
      gname <- paste0("Group ", g)
      gm    <- matches[matches$round == gname, ]
      teams <- unique(c(gm$team1, gm$team2))
      teams <- teams[teams != "TBD"]
      team_labels <- paste(sapply(teams, function(t) paste(flag(t), t)),
                           collapse = "  ·  ")
      
      cards <- lapply(seq_len(nrow(gm)), function(i) {
        m <- gm[i, ]
        make_match_card(m$match_id, m$team1, m$team2, m$date, m$venue)
      })
      
      div(id = paste0("gp_", g), style = if (g == "A") "display:block;" else "display:none;",
          div(class = "group-header-bar",
              span(class = "group-letter", paste("Group", g)),
              span(class = "group-teams-mini", team_labels)
          ),
          div(class = "group-card-wrap", tagList(cards))
      )
    })
    
    # Navigation pills
    nav_btns <- div(
      class = "group-nav",
      style = "display:flex; flex-wrap:wrap; gap:4px; margin:1rem 0 0.5rem;",
      lapply(groups, function(g) {
        tags$button(
          paste("Group", g),
          id      = paste0("gnavbtn_", g),
          class   = paste("nav-link", if (g == "A") "active" else ""),
          onclick = paste0(
            'document.querySelectorAll("[id^=gp_]").forEach(e=>{',
            'e.style.display="none";',
            '});',
            'document.getElementById("gp_', g, '").style.display="block";',
            'document.querySelectorAll("[id^=gnavbtn_]").forEach(e=>e.classList.remove("active"));',
            'this.classList.add("active");'
          )
        )
      })
    )
    
    tagList(nav_btns, tagList(group_divs))
  })
  
  # ── KNOCKOUT ROUNDS ──────────────────────────────────────────────────────────
  make_ko_ui <- function(round_name) {
    renderUI({
      matches <- r_matches()
      km      <- matches[matches$round == round_name, ]
      if (nrow(km) == 0) {
        return(div(style = "padding:2rem; color:#7a8f7c; text-align:center;",
                   paste0(round_name, " matchups will appear here after the previous round is complete.")))
      }
      cards <- lapply(seq_len(nrow(km)), function(i) {
        m <- km[i, ]
        make_match_card(m$match_id, m$team1, m$team2, m$date, m$venue, label = m$match_id)
      })
      div(
        div(class = "round-section-title", round_name),
        div(style = "display:grid; grid-template-columns:repeat(auto-fill,minmax(260px,1fr)); gap:0.75rem;",
            tagList(cards))
      )
    })
  }
  
  output$r32_ui   <- make_ko_ui("Round of 32")
  output$r16_ui   <- make_ko_ui("Round of 16")
  output$qf_ui    <- make_ko_ui("Quarterfinal")
  output$sf_ui    <- make_ko_ui("Semifinal")
  output$final_ui <- renderUI({
    matches <- r_matches()
    fm      <- matches[matches$round %in% c("Third Place", "Final"), ]
    if (nrow(fm) == 0) return(p("Final matchup TBD."))
    cards <- lapply(seq_len(nrow(fm)), function(i) {
      m <- fm[i, ]
      make_match_card(m$match_id, m$team1, m$team2, m$date, m$venue, label = m$round)
    })
    div(
      div(class = "round-section-title", "🏆 The Final · MetLife Stadium · July 19, 2026"),
      div(style = "max-width:460px;", tagList(cards))
    )
  })
  
  # ── LEADERBOARD ──────────────────────────────────────────────────────────────
  output$lb_ui <- renderUI({
    lb <- compute_leaderboard(r_votes(), r_results())
    if (nrow(lb) == 0) {
      return(div(style = "padding:3rem; text-align:center; color:#7a8f7c;",
                 "Scores will appear here once match results are entered."))
    }
    lb <- lb %>%
      mutate(
        `#`      = ifelse(Rank == 1, "🥇", ifelse(Rank == 2, "🥈",
                                                  ifelse(Rank == 3, "🥉", as.character(Rank)))),
        Player   = ifelse(!is.null(rv$player) & Player == rv$player,
                          paste0(Player, " ★"), Player)
      ) %>%
      select(`#`, Player, Points, Correct, `Total Picks` = Total_Picks)
    
    tagList(
      h4(style = "font-family:'Bebas Neue',sans-serif; color:#f0d88a; letter-spacing:0.08em; margin-bottom:1rem; font-size:1.6rem;",
         "🏆 Leaderboard"),
      DT::dataTableOutput("lb_table")
    )
  })
  
  output$lb_table <- DT::renderDataTable({
    lb <- compute_leaderboard(r_votes(), r_results())
    if (nrow(lb) == 0) return(data.frame())
    lb %>%
      mutate(
        `#`    = ifelse(Rank == 1, "🥇", ifelse(Rank == 2, "🥈",
                                                ifelse(Rank == 3, "🥉", as.character(Rank)))),
        Player = ifelse(!is.null(rv$player) & Player == rv$player,
                        paste0(Player, " ★"), Player)
      ) %>%
      select(`#`, Player, Points, Correct, `Total Picks` = Total_Picks)
  },
  rownames  = FALSE,
  class     = "table table-sm",
  elementId = "leaderboard-table",
  options   = list(
    pageLength = 50, searching = FALSE, info = FALSE,
    order      = list(list(2, "desc")),
    columnDefs = list(list(className = "dt-center", targets = c(0,2,3,4)))
  )
  )
  
  # ── ADMIN ────────────────────────────────────────────────────────────────────
  output$admin_unlocked <- reactive({ rv$admin_ok })
  outputOptions(output, "admin_unlocked", suspendWhenHidden = FALSE)
  
  observeEvent(input$admin_unlock_btn, {
    if (input$admin_pw_input == ADMIN_PASSWORD) {
      rv$admin_ok <- TRUE
    } else {
      output$admin_pw_error <- renderUI(
        p(style = "color:#cc3333; margin-top:0.5rem; font-size:0.85rem;",
          "Incorrect password.")
      )
    }
  })
  
  # Populate match selector
  observe({
    req(rv$admin_ok)
    matches <- r_matches()
    # Show only group stage + knockout matches that exist (team1 != TBD or results already in)
    choices <- setNames(matches$match_id,
                        paste0("[", matches$match_id, "] ",
                               matches$team1, " vs ", matches$team2,
                               "  (", matches$date, ")"))
    updateSelectInput(session, "admin_match_sel", choices = choices)
  })
  
  # Update winner dropdown based on selected match
  observeEvent(input$admin_match_sel, {
    req(rv$admin_ok, input$admin_match_sel)
    matches <- r_matches()
    m <- matches[matches$match_id == input$admin_match_sel, ]
    if (nrow(m) == 0) return()
    teams <- c(m$team1, m$team2)
    if (all(teams == "TBD")) teams <- c("Team 1", "Team 2")
    updateSelectInput(session, "admin_winner_sel",
                      choices = teams, selected = teams[1])
  })
  
  observeEvent(input$admin_save_btn, {
    req(rv$admin_ok, input$admin_match_sel, input$admin_winner_sel)
    tryCatch({
      save_result(
        match_id = input$admin_match_sel,
        winner   = input$admin_winner_sel,
        score    = ifelse(trimws(input$admin_score_inp) == "",
                          "N/A", trimws(input$admin_score_inp))
      )
      rv$data_version <- rv$data_version + 1
      showNotification(
        paste0("✓ Result saved: ", input$admin_match_sel,
               " → ", input$admin_winner_sel),
        type = "message", duration = 4
      )
    }, error = function(e) {
      showNotification(paste("Error:", e$message), type = "error")
    })
  })
  
  output$admin_votes_table <- DT::renderDataTable({
    req(rv$admin_ok)
    r_votes()
  }, rownames = FALSE, class = "table table-sm",
  options = list(pageLength = 20, scrollX = TRUE))
  
  output$admin_results_table <- DT::renderDataTable({
    req(rv$admin_ok)
    r_results()
  }, rownames = FALSE, class = "table table-sm",
  options = list(pageLength = 30, scrollX = TRUE))
  
  output$admin_dl_btn <- downloadHandler(
    filename = function() "votes.xlsx",
    content  = function(file) {
      file.copy(DATA_PATH, file)
    }
  )
}
