# ui file
# ui file

ui <- page_navbar(
  title = tags$span(
    tags$img(src = "trophy.svg", height = "28px", style = "margin-right:8px; vertical-align:middle;"),
    "World Cup 2026 Challenge"
  ),
  window_title = "WC2026 Challenge",
  theme = bs_theme(
    version        = 5,
    bg             = "#D1D4D1",
    fg             = "#474A4A",
    primary        = "#2A398D",
    secondary      = "#c9a84c",
    success        = "#198754",
    info           = "#1a7abf",
    warning        = "#c9a84c",
    danger         = "#cc3333",
    base_font      = font_google("DM Sans"),
    heading_font   = font_google("Bebas Neue"),
    font_scale     = 0.95,
    "navbar-bg"    = "#474A4A",
    "navbar-dark"  = TRUE,
    "body-bg"      = "#D1D4D1",
    "card-bg"      = "#D1D4D1",
    "card-border-color" = "#2a3a2c",
    "table-bg"     = "#D1D4D1",
    "table-striped-bg" = "#FFFFFF"
  ),
  useShinyjs(),
  
  # ── CSS overrides ────────────────────────────────────────────────────────
  header = tags$head(
    tags$style(HTML("
      :root {
        --wc-gold: #c9a84c;
        --wc-gold-light: #f0d88a;
        --wc-green: #2A398D;
        --wc-green-dark: #1a2a6e;
        --wc-surface: #D1D4D1;
        --wc-surface2: #FFFFFF;
        --wc-border: rgba(201,168,76,0.22);
        --wc-muted: #474A4A;
      }

      body { background-color: #D1D4D1 !important; }

      /* Hero banner */
      .wc-hero {
        background: linear-gradient(135deg, #2A398D 0%, #1a2a6e 100%);
        border-bottom: 2px solid var(--wc-gold);
        padding: 2rem 1.5rem 1.5rem;
        text-align: center;
        position: relative;
        overflow: hidden;
      }
      .wc-hero::before {
        content: '';
        position: absolute; inset: 0;
        background: repeating-linear-gradient(
          45deg, transparent, transparent 40px,
          rgba(255,255,255,0.015) 40px, rgba(255,255,255,0.015) 80px
        );
      }
      .wc-hero h1 {
        font-family: 'Bebas Neue', sans-serif;
        font-size: clamp(2.8rem, 8vw, 5.5rem);
        letter-spacing: 0.08em;
        color: var(--wc-gold-light);
        line-height: 1;
        margin: 0;
        position: relative;
      }
      .wc-hero .subtitle {
        color: rgba(240,237,228,0.55);
        letter-spacing: 0.15em;
        text-transform: uppercase;
        font-size: 0.82rem;
        margin-top: 0.35rem;
        position: relative;
      }
      .hero-badges {
        display: flex; gap: 1.5rem;
        justify-content: center; flex-wrap: wrap;
        margin-top: 1rem; position: relative;
      }
      .hero-badge {
        font-size: 0.72rem; color: var(--wc-gold);
        text-transform: uppercase; letter-spacing: 0.12em;
        border: 1px solid rgba(201,168,76,0.3);
        padding: 0.25rem 0.75rem; border-radius: 100px;
      }

      /* Player bar */
      .player-bar {
        background: #0e1a10;
        border-bottom: 1px solid var(--wc-border);
        padding: 0.6rem 1.2rem;
        display: flex; align-items: center;
        justify-content: space-between; flex-wrap: wrap; gap: 0.5rem;
      }
      .player-name { color: var(--wc-gold); font-weight: 600; font-size: 0.95rem; }
      .player-score { color: var(--wc-muted); font-size: 0.82rem; }
      .player-score strong { color: #FFFFFF; }

      /* Match card */
      .match-card {
        background: var(--wc-surface);
        border: 1px solid var(--wc-border);
        border-radius: 8px;
        padding: 0.6rem 0.7rem;
        margin-bottom: 0.55rem;
        transition: border-color 0.15s;
      }
      .match-card:hover { border-color: rgba(201,168,76,0.45); }
      .match-date-label {
        font-size: 0.67rem; color: var(--wc-muted);
        text-transform: uppercase; letter-spacing: 0.08em;
        margin-bottom: 0.35rem;
      }
      .match-teams-row {
        display: flex; align-items: center;
        gap: 0.4rem; justify-content: space-between;
      }

      /* Team vote buttons */
      .team-vote-btn {
        flex: 1;
        background: transparent !important;
        border: 1px solid rgba(255,255,255,0.14) !important;
        color: #FFFFFF !important;
        padding: 0.4rem 0.3rem !important;
        border-radius: 5px !important;
        font-size: 0.78rem !important;
        font-weight: 500 !important;
        transition: all 0.18s !important;
        text-align: center !important;
        white-space: normal !important;
        line-height: 1.25 !important;
        cursor: pointer !important;
        min-width: 0 !important;
        display: flex !important;
        flex-direction: column !important;
        align-items: center !important;
        gap: 2px !important;
      }
      .team-vote-btn:hover {
        background: rgba(201,168,76,0.14) !important;
        border-color: var(--wc-gold) !important;
      }
      .team-vote-btn.selected {
        background: #2A398D !important;
        border-color: #44cc66 !important;
        color: #FFFFFF !important;
        font-weight: 600 !important;
      }
      .team-vote-btn.result-correct {
        background: rgba(25,135,84,0.25) !important;
        border-color: #198754 !important;
        color: #6fdb9a !important;
      }
      .team-vote-btn.result-wrong {
        background: rgba(180,50,50,0.15) !important;
        border-color: rgba(180,50,50,0.4) !important;
        color: #d07070 !important;
      }
      .team-vote-btn .flag { font-size: 1.1rem; line-height: 1; }
      .team-vote-btn .tname { font-size: 0.72rem; }

      .vs-sep {
        font-size: 0.65rem; font-weight: 700;
        color: var(--wc-muted); flex-shrink: 0; padding: 0 2px;
      }

      .match-footer {
        margin-top: 0.3rem; font-size: 0.67rem;
        color: var(--wc-muted); text-align: center;
      }
      .result-score {
        display: inline-block;
        background: rgba(201,168,76,0.15);
        color: var(--wc-gold);
        border-radius: 3px; padding: 1px 6px;
        font-weight: 600; font-size: 0.68rem;
      }
      .correct-badge {
        display: inline-block;
        background: rgba(25,135,84,0.2);
        color: #6fdb9a;
        border-radius: 3px; padding: 1px 6px;
        font-size: 0.68rem; font-weight: 600;
      }
      .wrong-badge {
        display: inline-block;
        background: rgba(180,50,50,0.2);
        color: #d07070;
        border-radius: 3px; padding: 1px 6px;
        font-size: 0.68rem;
      }

      /* Group header */
      .group-header-bar {
        background: linear-gradient(90deg, var(--wc-green) 0%, var(--wc-green-dark) 100%);
        border-radius: 6px 6px 0 0;
        padding: 0.45rem 0.85rem;
        display: flex; align-items: center; gap: 0.6rem;
        border: 1px solid var(--wc-border);
        border-bottom: none;
        margin-bottom: 0;
      }
      .group-letter {
        font-family: 'Bebas Neue', sans-serif;
        font-size: 1.15rem; letter-spacing: 0.08em;
        color: var(--wc-gold-light);
      }
      .group-teams-mini { font-size: 0.68rem; color: rgba(240,237,228,0.5); }

      /* Group card wrapper */
      .group-card-wrap {
        background: var(--wc-surface);
        border: 1px solid var(--wc-border);
        border-top: none;
        border-radius: 0 0 8px 8px;
        padding: 0.5rem;
        margin-bottom: 1.25rem;
      }

      /* Bracket round card */
      .bracket-match-card {
        background: var(--wc-surface);
        border: 1px solid var(--wc-border);
        border-radius: 7px;
        padding: 0.65rem 0.75rem;
        margin-bottom: 0.65rem;
      }
      .bracket-match-label {
        font-size: 0.65rem; color: var(--wc-muted);
        text-transform: uppercase; letter-spacing: 0.1em;
        margin-bottom: 0.4rem;
      }
      .round-section-title {
        font-family: 'Bebas Neue', sans-serif;
        font-size: 1.6rem; color: var(--wc-gold-light);
        letter-spacing: 0.1em; margin-bottom: 1rem;
        padding-bottom: 0.4rem;
        border-bottom: 1px solid var(--wc-border);
      }

      /* Leaderboard table */
      #leaderboard-table table { color: #FFFFFF !important; }
      #leaderboard-table th {
        background: var(--wc-green) !important;
        color: var(--wc-gold-light) !important;
        font-family: 'Bebas Neue', sans-serif !important;
        letter-spacing: 0.08em !important; font-size: 0.9rem !important;
        border: none !important;
      }
      #leaderboard-table td {
        border-color: rgba(255,255,255,0.06) !important;
        font-size: 0.88rem !important;
      }
      #leaderboard-table tr:hover td { background: rgba(201,168,76,0.06) !important; }

      /* Nav pills for group selector */
      .group-nav .nav-link {
        font-family: 'Bebas Neue', sans-serif !important;
        letter-spacing: 0.08em !important;
        font-size: 0.9rem !important;
        color: var(--wc-muted) !important;
        padding: 0.3rem 0.65rem !important;
        border-radius: 4px !important;
        margin: 2px !important;
      }
      .group-nav .nav-link.active {
        background: var(--wc-green) !important;
        color: var(--wc-gold-light) !important;
      }

      /* Score pill */
      .score-pill {
        display: inline-block;
        background: #2A398D; color: #FFFFFF;
        border-radius: 100px; padding: 0.15rem 0.7rem;
        font-size: 0.78rem; font-weight: 600;
      }
      .rank-gold { color: var(--wc-gold); font-weight: 700; }
      .rank-silver { color: #aaaaaa; font-weight: 700; }
      .rank-bronze { color: #cd7f32; font-weight: 700; }

      /* Inputs */
      .form-control, .form-select {
        background: #FFFFFF !important;
        border-color: var(--wc-border) !important;
        color: #f0ede4 !important;
      }
      .form-control:focus {
        border-color: var(--wc-gold) !important;
        box-shadow: 0 0 0 2px rgba(201,168,76,0.2) !important;
      }
      .btn-wc-green {
        background: var(--wc-green) !important;
        border-color: var(--wc-green) !important;
        color: #FFFFFF !important;
        font-weight: 600;
      }
      .btn-wc-gold {
        background: transparent !important;
        border: 1px solid var(--wc-gold) !important;
        color: var(--wc-gold) !important;
        font-size: 0.82rem;
      }
      .btn-wc-gold:hover {
        background: var(--wc-gold) !important;
        color: #FFFFFF !important;
      }

      /* Tabs */
      .nav-tabs .nav-link {
        color: var(--wc-muted) !important;
        border: none !important;
        border-bottom: 2px solid transparent !important;
        font-size: 0.82rem !important;
        text-transform: uppercase !important;
        letter-spacing: 0.1em !important;
        padding: 0.6rem 1rem !important;
      }
      .nav-tabs .nav-link.active {
        color: var(--wc-gold) !important;
        border-bottom-color: var(--wc-gold) !important;
        background: transparent !important;
      }
      .nav-tabs { border-bottom: 1px solid var(--wc-border) !important; }

      .tab-content { padding-top: 1.25rem; }

      /* Notification */
      .shiny-notification {
        background: #2A398D !important;
        color: #FFFFFF !important;
        border-left: 3px solid #D4AF37 !important;
        font-size: 0.88rem !important;
      }

      /* Admin panel */
      .admin-section {
        background: rgba(180,50,50,0.07);
        border: 1px solid rgba(180,50,50,0.25);
        border-radius: 8px; padding: 1.25rem; margin-bottom: 1rem;
      }
      .admin-title {
        font-family: 'Bebas Neue', sans-serif;
        font-size: 1.2rem; color: #e06060; letter-spacing: 0.08em;
        margin-bottom: 0.75rem;
      }

      /* ── Auth modal ───────────────────────────────────────────────────── */
      .auth-modal-overlay {
        display: none; position: fixed; inset: 0;
        background: rgba(0,0,0,0.82); z-index: 9999;
        align-items: center; justify-content: center;
      }
      .auth-modal-overlay.open { display: flex; }
      .auth-modal {
        background: #1a2419; border: 1px solid rgba(201,168,76,0.35);
        border-radius: 12px; padding: 2rem; width: min(400px, 92vw);
        box-shadow: 0 20px 60px rgba(0,0,0,0.7);
      }
      .auth-modal h3 {
        font-family: 'Bebas Neue', sans-serif; font-size: 1.8rem;
        color: #f0d88a; letter-spacing: 0.06em; margin-bottom: 0.25rem;
      }
      .auth-modal .auth-sub {
        font-size: 0.82rem; color: #7a8f7c; margin-bottom: 1.25rem;
      }
      .auth-tabs { display: flex; gap: 0; margin-bottom: 1.25rem; border-bottom: 1px solid rgba(201,168,76,0.2); }
      .auth-tab-btn {
        flex: 1; background: none; border: none; color: #7a8f7c;
        font-family: 'DM Sans', sans-serif; font-size: 0.85rem;
        font-weight: 600; padding: 0.55rem; cursor: pointer;
        border-bottom: 2px solid transparent; text-transform: uppercase;
        letter-spacing: 0.08em; transition: all 0.15s;
      }
      .auth-tab-btn.active { color: #c9a84c; border-bottom-color: #c9a84c; }
      .auth-field { margin-bottom: 0.85rem; }
      .auth-field label { display: block; font-size: 0.75rem; color: #7a8f7c;
        text-transform: uppercase; letter-spacing: 0.08em; margin-bottom: 0.3rem; }
      .auth-error { color: #d07070; font-size: 0.82rem; margin: 0.5rem 0; min-height: 1.1rem; }
      .auth-success { color: #6fdb9a; font-size: 0.82rem; margin: 0.5rem 0; }
      .auth-footer { font-size: 0.75rem; color: #576857; margin-top: 1rem; text-align: center; }

      /* ── Teams ─────────────────────────────────────────────────────────── */
      .teams-section-title {
        font-family: 'Bebas Neue', sans-serif; font-size: 1.1rem;
        color: var(--wc-gold-light); letter-spacing: 0.08em; margin-bottom: 0.75rem;
      }
      .team-cards-row { display: flex; flex-wrap: wrap; gap: 0.75rem; margin-bottom: 0.5rem; }
      .team-card {
        background: var(--wc-surface); border: 1px solid var(--wc-border);
        border-radius: 8px; padding: 0.8rem 1rem; min-width: 160px;
        display: flex; flex-direction: column; gap: 0.3rem;
      }
      .team-card-name { font-weight: 600; font-size: 0.92rem; color: #f0ede4; }
      .team-card-meta { font-size: 0.75rem; color: var(--wc-muted); }
      .team-leave-btn {
        background: transparent !important; border: 1px solid rgba(204,51,51,0.45) !important;
        color: #d07070 !important; font-size: 0.72rem !important;
        padding: 0.2rem 0.6rem !important; margin-top: 0.35rem; align-self: flex-start;
      }
      .team-leave-btn:hover { background: rgba(204,51,51,0.15) !important; }
      .teams-input-label { font-size: 0.74rem; color: var(--wc-muted);
        text-transform: uppercase; letter-spacing: 0.08em; margin-bottom: 0.3rem; }
      .team-msg-ok  { color: #6fdb9a; font-size: 0.82rem; margin-top: 0.4rem; }
      .team-msg-err { color: #d07070; font-size: 0.82rem; margin-top: 0.4rem; }
      .all-teams-grid { display: flex; flex-wrap: wrap; gap: 0.5rem; }
      .all-team-chip {
        background: var(--wc-surface); border: 1px solid var(--wc-border);
        border-radius: 100px; padding: 0.3rem 0.85rem;
        display: flex; align-items: center; gap: 0.5rem;
      }
      .all-team-name  { font-size: 0.82rem; font-weight: 600; color: #f0ede4; }
      .all-team-count { font-size: 0.7rem;  color: var(--wc-muted); }

      /* ── Leaderboard sub-tabs ──────────────────────────────────────────── */
      .lb-subtabs {
        display: flex; gap: 4px; margin: 0.75rem 0 1.25rem;
        border-bottom: 1px solid var(--wc-border); padding-bottom: 0;
      }
      .lb-subtab-btn {
        background: none; border: none; color: var(--wc-muted);
        font-family: 'DM Sans', sans-serif; font-size: 0.82rem; font-weight: 600;
        padding: 0.5rem 1.1rem; cursor: pointer; border-bottom: 2px solid transparent;
        text-transform: uppercase; letter-spacing: 0.1em; transition: all 0.15s;
        margin-bottom: -1px;
      }
      .lb-subtab-btn.active { color: var(--wc-gold); border-bottom-color: var(--wc-gold); }
      .lb-subtab-btn:hover  { color: #f0ede4; }
      .lb-section-title {
        font-family: 'Bebas Neue', sans-serif; font-size: 1.5rem;
        color: var(--wc-gold-light); letter-spacing: 0.08em; margin-bottom: 0.85rem;
      }
    "))
  ),
  
  # ─────────────────────────────────────────────────────────────────────────────
  # NAV PANEL: Home / Picks
  # ─────────────────────────────────────────────────────────────────────────────
  nav_panel(
    "🏟️ Picks",
    # Hero
    div(class = "wc-hero",
        h1("World Cup 2026"),
        div(class = "subtitle", "Prediction Challenge · USA · Canada · Mexico"),
        div(class = "hero-badges",
            span(class = "hero-badge", "Jun 11 – Jul 19, 2026"),
            span(class = "hero-badge", "48 Teams"),
            span(class = "hero-badge", "104 Matches"),
            span(class = "hero-badge", "12 Groups")
        )
    ),
    
    # Player bar
    uiOutput("player_bar_ui"),
    
    # ── Auth modal (login / register) ─────────────────────────────────────────
    # Shown when no user is logged in; hidden once authenticated
    div(
      id = "auth-modal-overlay", class = "auth-modal-overlay",
      div(class = "auth-modal",
          h3("Join the Challenge"),
          div(class = "auth-sub", "Create an account or log in to save your picks"),
          # Tab switcher
          div(class = "auth-tabs",
              tags$button("Log In",   id = "auth-tab-login",    class = "auth-tab-btn active",
                          onclick = "switchAuthTab('login')"),
              tags$button("Register", id = "auth-tab-register", class = "auth-tab-btn",
                          onclick = "switchAuthTab('register')")
          ),
          # Login form
          div(id = "auth-form-login",
              div(class = "auth-field",
                  tags$label("Username"),
                  textInput("login_username", NULL, placeholder = "Your username", width = "100%")
              ),
              div(class = "auth-field",
                  tags$label("Password"),
                  passwordInput("login_password", NULL, placeholder = "Your password", width = "100%")
              ),
              uiOutput("login_error_ui"),
              actionButton("login_btn", "Log In →",
                           class = "btn btn-wc-green w-100", style = "margin-top:0.25rem;")
          ),
          # Register form (hidden by default)
          div(id = "auth-form-register", style = "display:none;",
              div(class = "auth-field",
                  tags$label("Choose a username"),
                  textInput("reg_username", NULL, placeholder = "e.g. Rodrigo or PabloFC", width = "100%")
              ),
              div(class = "auth-field",
                  tags$label("Choose a password"),
                  passwordInput("reg_password", NULL, placeholder = "At least 4 characters", width = "100%")
              ),
              div(class = "auth-field",
                  tags$label("Confirm password"),
                  passwordInput("reg_password2", NULL, placeholder = "Repeat password", width = "100%")
              ),
              uiOutput("register_error_ui"),
              actionButton("register_btn", "Create Account →",
                           class = "btn btn-wc-green w-100", style = "margin-top:0.25rem;")
          ),
          div(class = "auth-footer", "Your picks are saved to your account and persist across sessions.")
      )
    ),
    # JS for tab switching
    tags$script(HTML("
      function switchAuthTab(tab) {
        document.getElementById('auth-form-login').style.display    = tab==='login'    ? '' : 'none';
        document.getElementById('auth-form-register').style.display = tab==='register' ? '' : 'none';
        document.getElementById('auth-tab-login').classList.toggle('active',    tab==='login');
        document.getElementById('auth-tab-register').classList.toggle('active', tab==='register');
      }
      // Show modal when Shiny signals user is logged out
      Shiny.addCustomMessageHandler('show_auth_modal', function(x) {
        document.getElementById('auth-modal-overlay').classList.add('open');
      });
      Shiny.addCustomMessageHandler('hide_auth_modal', function(x) {
        document.getElementById('auth-modal-overlay').classList.remove('open');
      });
    ")),
    
    # Tabs: Groups | Knockout | Leaderboard
    div(
      style = "max-width:1200px; margin:0 auto; padding:0 1rem;",
      tabsetPanel(
        id = "main_tabs",
        tabPanel("Group Stage",    value = "groups",    uiOutput("groups_ui")),
        tabPanel("Round of 32",    value = "r32",       uiOutput("r32_ui")),
        tabPanel("Round of 16",    value = "r16",       uiOutput("r16_ui")),
        tabPanel("Quarterfinals",  value = "qf",        uiOutput("qf_ui")),
        tabPanel("Semifinals",     value = "sf",        uiOutput("sf_ui")),
        tabPanel("Final",          value = "final",     uiOutput("final_ui")),
        tabPanel("🏆 Leaderboard", value = "lb",        uiOutput("lb_ui")),
        tabPanel("👥 My Teams",    value = "teams",    uiOutput("teams_tab_ui"))
      )
    )
  ),
  
  # ─────────────────────────────────────────────────────────────────────────────
  # NAV PANEL: How it works
  # ─────────────────────────────────────────────────────────────────────────────
  nav_panel(
    "ℹ️ How It Works",
    div(style = "max-width:800px; margin:2rem auto; padding:0 1rem;",
        h2(style = "font-family:'Bebas Neue',sans-serif; color:#f0d88a; letter-spacing:0.06em; font-size:2rem; margin-bottom:1.5rem;",
           "How the Challenge Works"),
        layout_columns(
          col_widths = c(6, 6),
          card(
            card_header("1 · Enter your name"),
            p("Type your name on the Picks page. It's saved in your browser session — no account needed.")
          ),
          card(
            card_header("2 · Pick match winners"),
            p("For any upcoming match, click a team button to vote for that team. You can change your pick anytime before the match kicks off.")
          ),
          card(
            card_header("3 · Earn points"),
            p("Each correct prediction earns 1 point. Knockout-round picks are worth the same — no multipliers — keeping it simple.")
          ),
          card(
            card_header("4 · Win the challenge"),
            p("The player with the most correct picks at the end of the tournament wins. Tiebreaker: most picks in the Final.")
          )
        ),
        br(),
        card(
          card_header("📊 For the group admin"),
          p("Run the R Shiny app locally or deploy to shinyapps.io. The Admin panel (locked with a password set in ",
            code("global.R"), ") lets you enter official results after each match. Results are written back to ",
            code("data/votes.xlsx"), " and scores update instantly for all players."),
          p("To deploy: push the ", code("app/"), " folder plus ", code("data/"), " to GitHub, then connect to shinyapps.io via ",
            code("rsconnect::deployApp()"), ".")
        )
    )
  ),
  
  # ─────────────────────────────────────────────────────────────────────────────
  # NAV PANEL: Admin
  # ─────────────────────────────────────────────────────────────────────────────
  nav_panel(
    "🔒 Admin",
    div(style = "max-width:900px; margin:2rem auto; padding:0 1rem;",
        # Password gate
        conditionalPanel(
          condition = "output.admin_unlocked == false",
          div(style = "text-align:center; padding:3rem 0;",
              h3(style = "font-family:'Bebas Neue',sans-serif; color:#e06060; letter-spacing:0.08em; font-size:2rem;",
                 "Admin Access"),
              div(style = "display:flex; gap:0.6rem; justify-content:center; flex-wrap:wrap; margin-top:1rem;",
                  passwordInput("admin_pw_input", NULL, placeholder = "Password…", width = "220px"),
                  actionButton("admin_unlock_btn", "Unlock", class = "btn btn-danger")
              ),
              uiOutput("admin_pw_error")
          )
        ),
        
        # Admin panel content
        conditionalPanel(
          condition = "output.admin_unlocked == true",
          div(class = "admin-section",
              div(class = "admin-title", "🔴 Enter Match Result"),
              layout_columns(
                col_widths = c(4, 3, 3, 2),
                selectInput("admin_match_sel", "Match",
                            choices = NULL, width = "100%"),
                selectInput("admin_winner_sel", "Winner",
                            choices = NULL, width = "100%"),
                textInput("admin_score_inp", "Score (e.g. 2-1)",
                          placeholder = "2-1", width = "100%"),
                div(style = "padding-top:1.65rem;",
                    actionButton("admin_save_btn", "Save Result",
                                 class = "btn btn-danger w-100"))
              ),
              uiOutput("admin_save_status")
          ),
          div(class = "admin-section",
              div(class = "admin-title", "📋 All Votes"),
              DT::dataTableOutput("admin_votes_table")
          ),
          div(class = "admin-section",
              div(class = "admin-title", "📊 Results Entered"),
              DT::dataTableOutput("admin_results_table")
          ),
          div(style = "margin-bottom:2rem;",
              downloadButton("admin_dl_btn", "⬇ Download votes.xlsx",
                             class = "btn btn-wc-gold")
          )
        )
    )
  ),
  
  nav_spacer(),
  nav_item(
    tags$small(style = "color:#7a8f7c; padding:0 0.75rem;",
               "June 11 – July 19, 2026")
  )
)
