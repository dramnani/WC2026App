# server.R

server <- function(input, output, session) {
  
  # ── Reactive state ──────────────────────────────────────────────────────────
  rv <- reactiveValues(
    player       = NULL,
    admin_ok     = FALSE,
    data_version = 0,
    active_group = "A"
  )
  
  autoInvalidate <- reactiveTimer(30000)
  
  # Show auth modal on session start
  observe({
    if (is.null(rv$player))
      session$sendCustomMessage("show_auth_modal", list())
    else
      session$sendCustomMessage("hide_auth_modal", list())
  })
  
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
  
  r_teams <- reactive({
    rv$data_version
    autoInvalidate()
    read_teams()
  })
  
  my_picks <- reactive({
    if (is.null(rv$player)) return(setNames(character(0), character(0)))
    votes <- r_votes()
    mine  <- votes[votes$player == rv$player, ]
    if (nrow(mine) == 0) return(setNames(character(0), character(0)))
    setNames(as.character(mine$pick), as.character(mine$match_id))
  })
  
  # ── Auth flag for conditionalPanel ──────────────────────────────────────────
  output$user_logged_in <- reactive({ !is.null(rv$player) })
  outputOptions(output, "user_logged_in", suspendWhenHidden = FALSE)
  
  # ── Register ─────────────────────────────────────────────────────────────────
  output$register_error_ui <- renderUI(NULL)
  
  observeEvent(input$register_btn, {
    pw1 <- input$reg_password
    pw2 <- input$reg_password2
    if (pw1 != pw2) {
      output$register_error_ui <- renderUI(div(class = "auth-error", "Passwords do not match."))
      return()
    }
    result <- register_user(input$reg_username, pw1)
    if (!result$ok) {
      output$register_error_ui <- renderUI(div(class = "auth-error", result$message))
    } else {
      output$register_error_ui <- renderUI(div(class = "auth-success", result$message))
      rv$data_version <- rv$data_version + 1
      Sys.sleep(0.8)
      rv$player <- trimws(input$reg_username)
      session$sendCustomMessage("hide_auth_modal", list())
      showNotification(result$message, type = "message", duration = 4)
    }
  })
  
  # ── Login ────────────────────────────────────────────────────────────────────
  output$login_error_ui <- renderUI(NULL)
  
  observeEvent(input$login_btn, {
    result <- verify_login(input$login_username, input$login_password)
    if (!result$ok) {
      output$login_error_ui <- renderUI(div(class = "auth-error", result$message))
    } else {
      output$login_error_ui <- renderUI(NULL)
      rv$player <- result$username
      session$sendCustomMessage("hide_auth_modal", list())
      showNotification(result$message, type = "message", duration = 3)
    }
  })
  
  # ── Logout ───────────────────────────────────────────────────────────────────
  observeEvent(input$logout_btn, {
    rv$player <- NULL
    session$sendCustomMessage("show_auth_modal", list())
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
          span(class = "player-name", paste0("\U0001F464 ", rv$player)),
          tags$span(style = "margin-left:1rem;", class = "player-score",
                    "Score: ", tags$strong(paste0(pts, " pts")),
                    tags$span(style = "margin-left:0.75rem;",
                              paste0(npicks, " pick", if (npicks != 1) "s" else "", " made"))
          )
        ),
        actionButton("logout_btn", "Log out", class = "btn btn-sm btn-wc-outline")
    )
  })
  
  # ── Vote button observers ─────────────────────────────────────────────────────
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
            rest      <- sub("^vote_", "", b)
            parts     <- strsplit(rest, "_", fixed = TRUE)[[1]]
            matches_df <- isolate(r_matches())
            known_ids  <- as.character(matches_df$match_id)
            match_id  <- NA_character_
            pick_val  <- NA_character_
            for (n in seq(length(parts), 1)) {
              candidate <- paste(parts[1:n], collapse = "_")
              if (candidate %in% known_ids) {
                match_id <- candidate
                suffix   <- paste(parts[(n+1):length(parts)], collapse = "_")
                pick_val <- if (suffix == "draw") "draw"
                else gsub("_SPC_", " ", gsub("_DOT_", ".", suffix))
                break
              }
            }
            if (is.na(match_id) || is.na(pick_val) || pick_val == "") return()
            team <- pick_val
            tryCatch({
              save_vote(rv$player, match_id, team)
              rv$data_version <- rv$data_version + 1
              label <- if (team == "draw") "\u00bd Draw" else paste0(flag(team), " ", team)
              showNotification(paste0("\u2713 Picked ", label),
                               type = "message", duration = 2)
            }, error = function(e) {
              showNotification(paste("Save error:", e$message), type = "error")
            })
          }, ignoreInit = TRUE)
        })
      }
    }
  })
  
  # Persist the active group tab so re-renders restore the correct panel
  observeEvent(input$active_group, {
    rv$active_group <- input$active_group
  }, ignoreNULL = TRUE, ignoreInit = TRUE)
  
  # ── Match card renderer ───────────────────────────────────────────────────────
  make_match_card <- function(match_id, team1, team2, date_str,
                              venue_str = NULL, label = NULL, is_group = FALSE) {
    match_id  <- as.character(match_id[[1]])
    team1     <- as.character(team1[[1]])
    team2     <- as.character(team2[[1]])
    date_str  <- as.character(date_str[[1]])
    venue_str <- if (!is.null(venue_str)) as.character(venue_str[[1]]) else NULL
    label     <- if (!is.null(label))     as.character(label[[1]])     else NULL
    
    picks_now   <- my_picks()
    results_now <- r_results()
    votes_now   <- r_votes()
    
    my_pick <- picks_now[match_id]
    if (length(my_pick) == 0 || is.na(my_pick)) my_pick <- NULL
    
    result_row <- results_now[results_now$match_id == match_id, ]
    has_result <- nrow(result_row) > 0
    winner     <- if (has_result) as.character(result_row$winner[1]) else NULL
    score_str  <- if (has_result) as.character(result_row$score[1])  else NULL
    
    mv    <- votes_now[votes_now$match_id == match_id, ]
    n1    <- sum(mv$pick == team1,  na.rm = TRUE)
    n2    <- sum(mv$pick == team2,  na.rm = TRUE)
    ndraw <- sum(mv$pick == "draw", na.rm = TRUE)
    
    safe    <- function(t) gsub("\\.", "_DOT_", gsub(" ", "_SPC_", t))
    id1     <- paste0("vote_", match_id, "_", safe(team1))
    id2     <- paste0("vote_", match_id, "_", safe(team2))
    id_draw <- paste0("vote_", match_id, "_draw")
    
    cls_base <- "btn btn-sm team-vote-btn"
    cls1 <- cls_base; cls2 <- cls_base
    cls_draw <- paste(cls_base, "draw-btn")
    is_draw  <- isTRUE(winner == "draw")
    
    if (!is.null(my_pick)) {
      if (isTRUE(my_pick == team1))  cls1     <- paste(cls1,     "selected")
      if (isTRUE(my_pick == team2))  cls2     <- paste(cls2,     "selected")
      if (isTRUE(my_pick == "draw")) cls_draw <- paste(cls_draw, "selected")
      if (has_result) {
        if (isTRUE(my_pick == team1))
          cls1 <- paste(cls1, if (isTRUE(winner == team1)) "result-correct" else "result-wrong")
        if (isTRUE(my_pick == team2))
          cls2 <- paste(cls2, if (isTRUE(winner == team2)) "result-correct" else "result-wrong")
        if (isTRUE(my_pick == "draw"))
          cls_draw <- paste(cls_draw, if (is_draw) "result-correct" else "result-wrong")
      }
    }
    
    locked   <- is.null(rv$player) || has_result || team1 == "TBD" || team2 == "TBD"
    make_btn <- function(id, lbl_tag, cls) {
      if (locked) div(class = cls, style = "cursor:default; pointer-events:none;", lbl_tag)
      else        actionButton(id, label = lbl_tag, class = cls)
    }
    
    team_btn1 <- make_btn(id1,
                          tagList(span(class = "flag", flag(team1)), br(), span(class = "tname", team1)), cls1)
    team_btn2 <- make_btn(id2,
                          tagList(span(class = "flag", flag(team2)), br(), span(class = "tname", team2)), cls2)
    draw_btn  <- if (is_group)
      make_btn(id_draw,
               tagList(span(class = "draw-icon", "\u00bd"), br(), span(class = "tname", "Draw")), cls_draw)
    else NULL
    
    footer_items <- list()
    if (has_result) {
      result_label <- if (is_draw) paste0(score_str, "  \u00b7  Result: Draw")
      else paste0(score_str, "  \u00b7  Winner: ", flag(winner), " ", winner)
      footer_items[[length(footer_items)+1]] <-
        span(class = "result-score", result_label)
    }
    if (!is.null(my_pick) && has_result) {
      picked_correct <- (isTRUE(my_pick == winner)) ||
        (isTRUE(my_pick == "draw") && is_draw)
      footer_items[[length(footer_items)+1]] <-
        if (picked_correct) span(class = "correct-badge ms-1", " \u2713 Correct!")
      else {
        pick_label <- if (my_pick == "draw") "Draw"
        else paste0(flag(my_pick), " ", my_pick)
        span(class = "wrong-badge ms-1", paste0(" \u2717 You picked ", pick_label))
      }
    } else if (!is.null(my_pick) && !has_result) {
      pick_label <- if (my_pick == "draw") "\u00bd Draw"
      else paste0(flag(my_pick), " ", my_pick)
      footer_items[[length(footer_items)+1]] <-
        tags$small(style = "color:#2a7d29;", paste0("Your pick: ", pick_label))
    }
    count_str <- if (is_group)
      paste0(n1+n2+ndraw, " picks \u00b7 ", team1, ": ", n1, " / Draw: ", ndraw, " / ", team2, ": ", n2)
    else
      paste0(n1 + n2, " picks \u00b7 ", team1, ": ", n1, " / ", team2, ": ", n2)
    footer_items[[length(footer_items)+1]] <-
      tags$small(style = "color:#6b6e6b; font-size:0.65rem;", count_str)
    
    div(class = "match-card",
        if (!is.null(label)) div(class = "bracket-match-label", label),
        div(class = "match-date-label",
            if (!is.null(venue_str)) paste0(date_str, "  \u00b7  ", venue_str) else date_str),
        if (is_group) {
          div(class = "match-teams-row", team_btn1, draw_btn, team_btn2)
        } else {
          div(class = "match-teams-row", team_btn1, span(class = "vs-sep", "vs"), team_btn2)
        },
        div(class = "match-footer", tagList(footer_items))
    )
  }
  
  # ── Group stage ───────────────────────────────────────────────────────────────
  output$groups_ui <- renderUI({
    matches <- r_matches()
    if (nrow(matches) == 0)
      return(div(style = "padding:2rem; color:#6b6e6b;", "Loading match data\u2026"))
    
    groups <- LETTERS[1:12]
    
    group_divs <- lapply(groups, function(g) {
      gname <- paste0("Group ", g)
      gm    <- matches[matches$round == gname, ]
      teams <- unique(c(as.character(gm$team1), as.character(gm$team2)))
      teams <- teams[teams != "TBD"]
      team_labels <- paste(sapply(teams, function(t) paste(flag(t), t)), collapse = "  \u00b7  ")
      
      cards <- lapply(seq_len(nrow(gm)), function(i) {
        tryCatch(
          make_match_card(gm$match_id[i], gm$team1[i], gm$team2[i], gm$date[i], gm$venue[i], is_group = TRUE),
          error = function(e) div(class = "match-card",
                                  style = "color:#6b6e6b; font-size:0.8rem;", paste("Error:", e$message))
        )
      })
      
      div(id = paste0("gp_", g),
          style = if (g == rv$active_group) "display:block;" else "display:none;",
          div(class = "group-header-bar",
              span(class = "group-letter", paste("Group", g)),
              span(class = "group-teams-mini", team_labels)),
          div(class = "group-card-wrap", tagList(cards))
      )
    })
    
    nav_btns <- div(
      class = "group-nav",
      style = "display:flex; flex-wrap:wrap; gap:4px; margin:1rem 0 0.5rem;",
      lapply(groups, function(g) {
        tags$button(
          paste("Group", g), id = paste0("gnavbtn_", g),
          class = paste("nav-link", if (g == rv$active_group) "active" else ""),
          onclick = paste0(
            'document.querySelectorAll("[id^=gp_]").forEach(e=>e.style.display="none");',
            'document.getElementById("gp_', g, '").style.display="block";',
            'document.querySelectorAll("[id^=gnavbtn_]").forEach(e=>e.classList.remove("active"));',
            'this.classList.add("active");',
            'Shiny.setInputValue("active_group","', g, '",{priority:"event"});'
          )
        )
      })
    )
    tagList(nav_btns, tagList(group_divs))
  })
  
  # ── Knockout rounds ───────────────────────────────────────────────────────────
  make_ko_ui <- function(round_name) {
    renderUI({
      matches <- r_matches()
      if (nrow(matches) == 0)
        return(div(style = "padding:2rem; color:#6b6e6b;", "Loading\u2026"))
      km <- matches[matches$round == round_name, ]
      if (nrow(km) == 0)
        return(div(style = "padding:2rem; color:#6b6e6b; text-align:center;",
                   paste0(round_name, " matchups will appear once teams advance.")))
      cards <- lapply(seq_len(nrow(km)), function(i) {
        tryCatch(
          make_match_card(km$match_id[i], km$team1[i], km$team2[i],
                          km$date[i], km$venue[i], label = km$match_id[i]),
          error = function(e) div(class = "match-card", style = "color:#6b6e6b; font-size:0.8rem;", e$message)
        )
      })
      div(
        div(class = "round-section-title", round_name),
        div(style = "display:grid; grid-template-columns:repeat(auto-fill,minmax(260px,1fr)); gap:0.75rem;",
            tagList(cards))
      )
    })
  }
  
  output$r32_ui  <- make_ko_ui("Round of 32")
  output$r16_ui  <- make_ko_ui("Round of 16")
  output$qf_ui   <- make_ko_ui("Quarterfinal")
  output$sf_ui   <- make_ko_ui("Semifinal")
  
  output$final_ui <- renderUI({
    matches <- r_matches()
    if (nrow(matches) == 0) return(p("Loading\u2026"))
    fm <- matches[matches$round %in% c("Third Place","Final"), ]
    if (nrow(fm) == 0) return(p(style = "color:#6b6e6b;", "Final matchup TBD."))
    cards <- lapply(seq_len(nrow(fm)), function(i) {
      tryCatch(
        make_match_card(fm$match_id[i], fm$team1[i], fm$team2[i],
                        fm$date[i], fm$venue[i], label = fm$round[i]),
        error = function(e) div(class = "match-card", style = "color:#6b6e6b;", e$message)
      )
    })
    div(
      div(class = "round-section-title",
          "\U0001F3C6 The Final \u00b7 MetLife Stadium \u00b7 July 19, 2026"),
      div(style = "max-width:460px;", tagList(cards))
    )
  })
  
  # ── Leaderboard ───────────────────────────────────────────────────────────────
  output$lb_ui <- renderUI({
    tagList(
      div(class = "lb-subtabs",
          tags$button("Individual", id = "lbtab-ind",  class = "lb-subtab-btn active",
                      onclick = "switchLbTab('ind')"),
          tags$button("Teams",      id = "lbtab-team", class = "lb-subtab-btn",
                      onclick = "switchLbTab('team')")
      ),
      div(id = "lb-panel-ind",  uiOutput("lb_individual_ui")),
      div(id = "lb-panel-team", style = "display:none;", uiOutput("lb_team_ui")),
      tags$script(HTML("
        function switchLbTab(tab) {
          document.getElementById('lb-panel-ind').style.display  = tab==='ind'  ? '' : 'none';
          document.getElementById('lb-panel-team').style.display = tab==='team' ? '' : 'none';
          document.getElementById('lbtab-ind').classList.toggle('active',  tab==='ind');
          document.getElementById('lbtab-team').classList.toggle('active', tab==='team');
        }
      "))
    )
  })
  
  output$lb_individual_ui <- renderUI({
    lb <- compute_leaderboard(r_votes(), r_results())
    if (nrow(lb) == 0)
      return(div(style = "padding:2rem; text-align:center; color:#6b6e6b;",
                 "Scores will appear once match results are entered."))
    tagList(
      h4(class = "lb-section-title", "\U0001F947 Individual Rankings"),
      DT::dataTableOutput("lb_ind_table")
    )
  })
  
  output$lb_ind_table <- DT::renderDataTable({
    lb <- compute_leaderboard(r_votes(), r_results())
    if (nrow(lb) == 0) return(data.frame())
    teams_df <- r_teams()
    player_teams <- if (nrow(teams_df) > 0) {
      teams_df %>%
        group_by(username) %>%
        summarise(Teams = paste(team_name, collapse = ", "), .groups = "drop")
    } else data.frame(username=character(), Teams=character(), stringsAsFactors=FALSE)
    
    lb %>%
      left_join(player_teams, by = c("Player"="username")) %>%
      mutate(
        Teams  = ifelse(is.na(Teams), "\u2014", Teams),
        `#`    = dplyr::case_when(Rank==1~"\U0001F947", Rank==2~"\U0001F948",
                                  Rank==3~"\U0001F949", TRUE~as.character(Rank)),
        Player = ifelse(!is.null(rv$player) & Player == rv$player,
                        paste0(Player, " \u2605"), Player)
      ) %>%
      select(`#`, Player, Teams, Points, Correct, `Total Picks` = Total_Picks)
  },
  rownames = FALSE, class = "table table-sm", elementId = "lb-ind-table",
  options = list(pageLength=50, searching=FALSE, info=FALSE,
                 order=list(list(3,"desc")),
                 columnDefs=list(list(className="dt-center", targets=c(0,3,4,5))))
  )
  
  output$lb_team_ui <- renderUI({
    tl <- compute_team_leaderboard(r_votes(), r_results(), r_teams())
    if (nrow(tl) == 0)
      return(div(style = "padding:2rem; text-align:center; color:#6b6e6b;",
                 "No teams yet. Create or join a team on the My Teams tab!"))
    tagList(
      h4(class = "lb-section-title", "\U0001F6E1 Team Rankings"),
      DT::dataTableOutput("lb_team_table")
    )
  })
  
  output$lb_team_table <- DT::renderDataTable({
    tl <- compute_team_leaderboard(r_votes(), r_results(), r_teams())
    if (nrow(tl) == 0) return(data.frame())
    teams_df <- r_teams()
    my_teams <- if (!is.null(rv$player) && nrow(teams_df) > 0)
      teams_df$team_name[teams_df$username == rv$player]
    else character(0)
    tl %>%
      mutate(
        `#`      = dplyr::case_when(Rank==1~"\U0001F947", Rank==2~"\U0001F948",
                                    Rank==3~"\U0001F949", TRUE~as.character(Rank)),
        Team     = ifelse(Team %in% my_teams, paste0(Team, " \u2605"), Team),
        `Avg Pts` = Avg_Points
      ) %>%
      select(`#`, Team, Members, `Total Pts`=Total_Points, `Avg Pts`)
  },
  rownames = FALSE, class = "table table-sm", elementId = "lb-team-table",
  options = list(pageLength=30, searching=FALSE, info=FALSE,
                 order=list(list(3,"desc")),
                 columnDefs=list(list(className="dt-center", targets=c(0,2,3,4))))
  )
  
  # ── Team management ──────────────────────────────────────────────────────────
  output$my_teams_ui <- renderUI({
    req(rv$player)
    teams_df <- r_teams()
    my_memberships <- if (nrow(teams_df) > 0) teams_df[teams_df$username == rv$player, ]
    else empty_teams()
    n_teams <- nrow(my_memberships)
    
    team_cards <- if (n_teams > 0) {
      lapply(seq_len(n_teams), function(i) {
        tn <- my_memberships$team_name[i]
        n_members <- sum(tolower(teams_df$team_name) == tolower(tn))
        div(class = "team-card",
            div(class = "team-card-name", tn),
            div(class = "team-card-meta",
                paste0(n_members, " member", if(n_members!=1) "s" else "")),
            actionButton(paste0("leave_team_", gsub("[^A-Za-z0-9]","_",tn)),
                         "Leave", class = "btn btn-sm team-leave-btn",
                         onclick = sprintf(
                           "Shiny.setInputValue('leave_team_name','%s',{priority:'event'})", tn))
        )
      })
    } else {
      list(div(style="color:#6b6e6b; font-size:0.85rem; padding:0.5rem 0;",
               "You are not in any teams yet."))
    }
    
    can_join_more <- n_teams < MAX_TEAMS_PER_USER
    
    tagList(
      div(class = "teams-section-title", paste0("Your Teams (", n_teams, "/", MAX_TEAMS_PER_USER, ")")),
      div(class = "team-cards-row", tagList(team_cards)),
      if (can_join_more) {
        tagList(
          hr(style="border-color:var(--wc-border); margin:1.25rem 0;"),
          div(class = "teams-section-title", "Join or Create a Team"),
          layout_columns(
            col_widths = c(5, 2, 5),
            div(
              div(class = "teams-input-label", "Join an existing team"),
              div(style="display:flex; gap:0.5rem;",
                  textInput("join_team_name", NULL, placeholder="Team name\u2026", width="100%"),
                  actionButton("join_team_btn", "Join", class="btn btn-wc-blue")
              ),
              uiOutput("join_team_msg")
            ),
            div(style="display:flex; align-items:center; justify-content:center;
                       padding-top:1.4rem; color:#6b6e6b; font-size:0.85rem;", "or"),
            div(
              div(class = "teams-input-label", "Create a new team"),
              div(style="display:flex; gap:0.5rem;",
                  textInput("create_team_name", NULL, placeholder="New team name\u2026", width="100%"),
                  actionButton("create_team_btn", "Create", class="btn btn-wc-blue")
              ),
              uiOutput("create_team_msg")
            )
          )
        )
      } else {
        div(style="color:#6b6e6b; font-size:0.82rem; margin-top:1rem;",
            paste0("You've reached the maximum of ", MAX_TEAMS_PER_USER,
                   " teams. Leave one to join or create another."))
      }
    )
  })
  
  output$all_teams_ui <- renderUI({
    teams_df <- r_teams()
    if (nrow(teams_df) == 0)
      return(div(style="color:#6b6e6b; font-size:0.85rem; padding:0.5rem 0;",
                 "No teams have been created yet. Be the first!"))
    summary <- teams_df %>%
      group_by(team_name) %>%
      summarise(Members = n(), .groups="drop") %>%
      arrange(team_name)
    div(
      div(class="teams-section-title", paste0("All Teams (", nrow(summary), ")")),
      div(class="all-teams-grid",
          lapply(seq_len(nrow(summary)), function(i) {
            tn <- summary$team_name[i]; nm <- summary$Members[i]
            div(class="all-team-chip",
                span(class="all-team-name", tn),
                span(class="all-team-count", paste0(nm, " member", if(nm!=1)"s" else ""))
            )
          })
      )
    )
  })
  
  output$join_team_msg <- renderUI(NULL)
  observeEvent(input$join_team_btn, {
    req(rv$player, input$join_team_name)
    result <- join_team(trimws(input$join_team_name), rv$player)
    if (result$ok) {
      rv$data_version <- rv$data_version + 1
      updateTextInput(session, "join_team_name", value="")
      output$join_team_msg <- renderUI(div(class="team-msg-ok", result$message))
    } else {
      output$join_team_msg <- renderUI(div(class="team-msg-err", result$message))
    }
  })
  
  output$create_team_msg <- renderUI(NULL)
  observeEvent(input$create_team_btn, {
    req(rv$player, input$create_team_name)
    result <- create_team(trimws(input$create_team_name), rv$player)
    if (result$ok) {
      rv$data_version <- rv$data_version + 1
      updateTextInput(session, "create_team_name", value="")
      output$create_team_msg <- renderUI(div(class="team-msg-ok", result$message))
    } else {
      output$create_team_msg <- renderUI(div(class="team-msg-err", result$message))
    }
  })
  
  output$teams_tab_ui <- renderUI({
    if (is.null(rv$player)) {
      return(div(style="padding:2rem; text-align:center; color:#6b6e6b;",
                 "Please log in to manage your teams."))
    }
    tagList(
      uiOutput("my_teams_ui"),
      hr(style="border-color:var(--wc-border); margin:1.5rem 0;"),
      uiOutput("all_teams_ui")
    )
  })
  
  observeEvent(input$leave_team_name, {
    req(rv$player, input$leave_team_name)
    result <- leave_team(input$leave_team_name, rv$player)
    rv$data_version <- rv$data_version + 1
    showNotification(result$message, type="message", duration=3)
  })
  
  # ── Admin ─────────────────────────────────────────────────────────────────────
  output$admin_unlocked <- reactive({ rv$admin_ok })
  outputOptions(output, "admin_unlocked", suspendWhenHidden = FALSE)
  
  observeEvent(input$admin_unlock_btn, {
    if (input$admin_pw_input == ADMIN_PASSWORD) {
      rv$admin_ok <- TRUE
    } else {
      output$admin_pw_error <- renderUI(
        p(style = "color:#cc3333; margin-top:0.5rem; font-size:0.85rem;", "Incorrect password."))
    }
  })
  
  observe({
    req(rv$admin_ok)
    matches <- r_matches()
    choices <- setNames(as.character(matches$match_id),
                        paste0("[", matches$match_id, "] ",
                               matches$team1, " vs ", matches$team2,
                               "  (", matches$date, ")"))
    updateSelectInput(session, "admin_match_sel", choices = choices)
  })
  
  observeEvent(input$admin_match_sel, {
    req(rv$admin_ok, input$admin_match_sel)
    matches <- r_matches()
    m <- matches[matches$match_id == input$admin_match_sel, ]
    if (nrow(m) == 0) return()
    t1 <- as.character(m$team1[1]); t2 <- as.character(m$team2[1])
    if (t1 == "TBD") t1 <- "Team 1"; if (t2 == "TBD") t2 <- "Team 2"
    is_grp  <- grepl("^Group ", as.character(m$round[1]))
    choices <- if (is_grp) c(t1, "Draw", t2) else c(t1, t2)
    updateSelectInput(session, "admin_winner_sel", choices = choices, selected = choices[1])
  })
  
  observeEvent(input$admin_save_btn, {
    req(rv$admin_ok, input$admin_match_sel, input$admin_winner_sel)
    winner_val <- if (input$admin_winner_sel == "Draw") "draw" else input$admin_winner_sel
    tryCatch({
      save_result(input$admin_match_sel, winner_val,
                  ifelse(trimws(input$admin_score_inp)=="","N/A",trimws(input$admin_score_inp)))
      rv$data_version <- rv$data_version + 1
      showNotification(paste0("\u2713 Saved: ", input$admin_match_sel,
                              " \u2192 ", input$admin_winner_sel),
                       type = "message", duration = 4)
    }, error = function(e) showNotification(paste("Error:", e$message), type = "error"))
  })
  
  output$admin_votes_table <- DT::renderDataTable({
    req(rv$admin_ok); r_votes()
  }, rownames=FALSE, class="table table-sm", options=list(pageLength=20, scrollX=TRUE))
  
  output$admin_results_table <- DT::renderDataTable({
    req(rv$admin_ok); r_results()
  }, rownames=FALSE, class="table table-sm", options=list(pageLength=30, scrollX=TRUE))
  
  # Download votes as CSV (no local file dependency)
  output$admin_dl_btn <- downloadHandler(
    filename = function() paste0("wc2026_votes_", format(Sys.time(), "%Y%m%d_%H%M"), ".csv"),
    content  = function(file) {
      votes <- read_votes()
      write.csv(votes, file, row.names = FALSE)
    }
  )
}
