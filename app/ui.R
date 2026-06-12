# ui file

ui <- page_navbar(
  title = tags$span(
    "\U0001F3C6",
    tags$span(style = "margin-left:6px;", "World Cup 2026 Challenge")
  ),
  window_title = "WC2026 Challenge",
  theme = bs_theme(
    version      = 5,
    bg           = "#D1D4D1",
    fg           = "#474A4A",
    primary      = "#2A398D",
    secondary    = "#474A4A",
    success      = "#3CAC3B",
    info         = "#2A398D",
    warning      = "#c9a84c",
    danger       = "#cc3333",
    base_font    = font_google("DM Sans"),
    heading_font = font_google("Bebas Neue"),
    font_scale   = 0.95,
    "navbar-bg"          = "#2A398D",
    "navbar-dark"        = TRUE,
    "body-bg"            = "#D1D4D1",
    "card-bg"            = "#FFFFFF",
    "card-border-color"  = "#c8ccc8",
    "table-bg"           = "#FFFFFF",
    "table-striped-bg"   = "#edf0ed"
  ),
  useShinyjs(),
  
  # ── Global CSS ────────────────────────────────────────────────────────────
  header = tags$head(
    tags$style(HTML("
      /* ── Design tokens ─────────────────────────────────────────────────── */
      :root {
        --wc-bg:          #D1D4D1;
        --wc-bg2:         #FFFFFF;
        --wc-border:      #b8bcb8;
        --wc-blue:        #2A398D;
        --wc-blue-dark:   #1e2b6e;
        --wc-blue-light:  #3d50b0;
        --wc-green:       #3CAC3B;
        --wc-green-dark:  #2a7d29;
        --wc-dark:        #474A4A;
        --wc-muted:       #6b6e6b;
        --wc-light-text:  #FFFFFF;
      }

      /* ── Base page ─────────────────────────────────────────────────────── */
      body {
        background-color: var(--wc-bg) !important;
        color: var(--wc-dark) !important;
      }

      /* ── Navbar ────────────────────────────────────────────────────────── */
      .navbar {
        background-color: var(--wc-blue) !important;
        border-bottom: 3px solid var(--wc-green) !important;
      }
      .navbar-brand, .nav-link {
        color: #FFFFFF !important;
        font-weight: 600;
      }
      .navbar .nav-link.active,
      .navbar .nav-link:hover {
        color: #d4e8d4 !important;
        background: rgba(60,172,59,0.18) !important;
        border-radius: 4px;
      }

      /* ── Hero banner ───────────────────────────────────────────────────── */
      .wc-hero {
        background: linear-gradient(135deg, var(--wc-blue) 0%, var(--wc-blue-dark) 100%);
        border-bottom: 3px solid var(--wc-green);
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
          rgba(255,255,255,0.03) 40px, rgba(255,255,255,0.03) 80px
        );
      }
      .wc-hero h1 {
        font-family: 'Bebas Neue', sans-serif;
        font-size: clamp(2.8rem, 8vw, 5.5rem);
        letter-spacing: 0.08em;
        color: #FFFFFF;
        line-height: 1; margin: 0; position: relative;
      }
      .wc-hero .subtitle {
        color: rgba(255,255,255,0.72);
        letter-spacing: 0.15em; text-transform: uppercase;
        font-size: 0.82rem; margin-top: 0.35rem; position: relative;
      }
      .hero-badges {
        display: flex; gap: 1.5rem;
        justify-content: center; flex-wrap: wrap;
        margin-top: 1rem; position: relative;
      }
      .hero-badge {
        font-size: 0.72rem; color: #d4f0d4;
        text-transform: uppercase; letter-spacing: 0.12em;
        border: 1px solid rgba(60,172,59,0.55);
        padding: 0.25rem 0.75rem; border-radius: 100px;
        background: rgba(60,172,59,0.12);
      }

      /* ── Player bar ────────────────────────────────────────────────────── */
      .player-bar {
        background: var(--wc-blue-dark);
        border-bottom: 2px solid var(--wc-green);
        padding: 0.6rem 1.2rem;
        display: flex; align-items: center;
        justify-content: space-between; flex-wrap: wrap; gap: 0.5rem;
      }
      .player-name  { color: #FFFFFF; font-weight: 700; font-size: 0.95rem; }
      .player-score { color: rgba(255,255,255,0.72); font-size: 0.82rem; }
      .player-score strong { color: var(--wc-green); }

      /* ── Match card ────────────────────────────────────────────────────── */
      .match-card {
        background: var(--wc-bg2);
        border: 1px solid var(--wc-border);
        border-radius: 8px;
        padding: 0.6rem 0.7rem;
        margin-bottom: 0.55rem;
        transition: border-color 0.15s, box-shadow 0.15s;
      }
      .match-card:hover {
        border-color: var(--wc-blue-light);
        box-shadow: 0 2px 8px rgba(42,57,141,0.12);
      }
      .match-date-label {
        font-size: 0.67rem; color: var(--wc-muted);
        text-transform: uppercase; letter-spacing: 0.08em;
        margin-bottom: 0.35rem;
      }
      .match-teams-row {
        display: flex; align-items: center;
        gap: 0.4rem; justify-content: space-between;
      }

      /* ── Team vote buttons ─────────────────────────────────────────────── */
      .team-vote-btn {
        flex: 1;
        background: var(--wc-bg) !important;
        border: 1px solid var(--wc-border) !important;
        color: var(--wc-dark) !important;
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
        background: rgba(42,57,141,0.1) !important;
        border-color: var(--wc-blue) !important;
        color: var(--wc-blue) !important;
      }
      .team-vote-btn.selected {
        background: var(--wc-blue) !important;
        border-color: var(--wc-blue-dark) !important;
        color: #FFFFFF !important;
        font-weight: 700 !important;
      }
      .team-vote-btn.result-correct {
        background: rgba(60,172,59,0.18) !important;
        border-color: var(--wc-green) !important;
        color: var(--wc-green-dark) !important;
      }
      .team-vote-btn.result-wrong {
        background: rgba(180,50,50,0.1) !important;
        border-color: rgba(180,50,50,0.45) !important;
        color: #a33 !important;
      }
      .team-vote-btn .flag { font-size: 1.1rem; line-height: 1; }
      .team-vote-btn .tname { font-size: 0.72rem; }
      
      /* Draw button */
      .draw-btn {
        flex: 0 0 auto !important;
        width: 3.2rem !important;
        min-width: 3.2rem !important;
        background: transparent !important;
        border: 1px solid rgba(212,175,55,0.35) !important;
        color: #c9a84c !important;
      }
      .draw-btn:hover {
        background: rgba(212,175,55,0.12) !important;
        border-color: #D4AF37 !important;
        color: #D4AF37 !important;
      }
      .draw-btn.selected {
        background: rgba(212,175,55,0.18) !important;
        border-color: #D4AF37 !important;
        color: #D4AF37 !important;
        font-weight: 600 !important;
      }
      .draw-btn.result-correct {
        background: rgba(25,135,84,0.25) !important;
        border-color: #198754 !important;
        color: #6fdb9a !important;
      }
      .draw-btn.result-wrong {
        background: rgba(180,50,50,0.15) !important;
        border-color: rgba(180,50,50,0.4) !important;
        color: #d07070 !important;
      }
      .draw-icon { font-size: 1rem; line-height: 1; font-weight: 700; }

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
        background: rgba(42,57,141,0.12);
        color: var(--wc-blue);
        border-radius: 3px; padding: 1px 6px;
        font-weight: 700; font-size: 0.68rem;
      }
      .correct-badge {
        display: inline-block;
        background: rgba(60,172,59,0.18);
        color: var(--wc-green-dark);
        border-radius: 3px; padding: 1px 6px;
        font-size: 0.68rem; font-weight: 700;
      }
      .wrong-badge {
        display: inline-block;
        background: rgba(180,50,50,0.12);
        color: #a33;
        border-radius: 3px; padding: 1px 6px;
        font-size: 0.68rem;
      }

      /* ── Group header ──────────────────────────────────────────────────── */
      .group-header-bar {
        background: linear-gradient(90deg, var(--wc-blue) 0%, var(--wc-blue-dark) 100%);
        border-radius: 6px 6px 0 0;
        padding: 0.45rem 0.85rem;
        display: flex; align-items: center; gap: 0.6rem;
        border: 1px solid var(--wc-border); border-bottom: none;
      }
      .group-letter {
        font-family: 'Bebas Neue', sans-serif;
        font-size: 1.15rem; letter-spacing: 0.08em; color: #FFFFFF;
      }
      .group-teams-mini { font-size: 0.68rem; color: rgba(255,255,255,0.65); }

      .group-card-wrap {
        background: var(--wc-bg2);
        border: 1px solid var(--wc-border);
        border-top: none; border-radius: 0 0 8px 8px;
        padding: 0.5rem; margin-bottom: 1.25rem;
      }

      /* ── Knockout sections ─────────────────────────────────────────────── */
      .bracket-match-label {
        font-size: 0.65rem; color: var(--wc-muted);
        text-transform: uppercase; letter-spacing: 0.1em; margin-bottom: 0.4rem;
      }
      .round-section-title {
        font-family: 'Bebas Neue', sans-serif;
        font-size: 1.6rem; color: var(--wc-blue);
        letter-spacing: 0.1em; margin-bottom: 1rem;
        padding-bottom: 0.4rem;
        border-bottom: 2px solid var(--wc-green);
      }

      /* ── Group nav pills ───────────────────────────────────────────────── */
      .group-nav .nav-link {
        font-family: 'Bebas Neue', sans-serif !important;
        letter-spacing: 0.08em !important; font-size: 0.9rem !important;
        color: var(--wc-dark) !important;
        padding: 0.3rem 0.65rem !important;
        border-radius: 4px !important; margin: 2px !important;
        background: var(--wc-bg2) !important;
        border: 1px solid var(--wc-border) !important;
      }
      .group-nav .nav-link.active {
        background: var(--wc-blue) !important;
        color: #FFFFFF !important;
        border-color: var(--wc-blue-dark) !important;
      }
      .group-nav .nav-link:hover {
        background: rgba(42,57,141,0.1) !important;
        color: var(--wc-blue) !important;
      }

      /* ── Main tab nav ──────────────────────────────────────────────────── */
      .nav-tabs .nav-link {
        color: var(--wc-muted) !important;
        border: none !important;
        border-bottom: 2px solid transparent !important;
        font-size: 0.82rem !important;
        text-transform: uppercase !important;
        letter-spacing: 0.1em !important;
        padding: 0.6rem 1rem !important;
        background: transparent !important;
      }
      .nav-tabs .nav-link.active {
        color: var(--wc-blue) !important;
        border-bottom-color: var(--wc-blue) !important;
        font-weight: 700 !important;
      }
      .nav-tabs .nav-link:hover { color: var(--wc-blue) !important; }
      .nav-tabs { border-bottom: 1px solid var(--wc-border) !important; }
      .tab-content { padding-top: 1.25rem; }

      /* ── Buttons ───────────────────────────────────────────────────────── */
      .btn-wc-blue, .btn-wc-green {
        background: var(--wc-blue) !important;
        border-color: var(--wc-blue-dark) !important;
        color: #FFFFFF !important;
        font-weight: 700;
      }
      .btn-wc-blue:hover, .btn-wc-green:hover {
        background: var(--wc-blue-dark) !important;
      }
      .btn-wc-outline {
        background: transparent !important;
        border: 1px solid var(--wc-blue) !important;
        color: var(--wc-blue) !important;
        font-size: 0.82rem; font-weight: 600;
      }
      .btn-wc-outline:hover {
        background: var(--wc-blue) !important;
        color: #FFFFFF !important;
      }
      /* keep old class names working */
      .btn-wc-gold { }

      /* ── Form inputs ───────────────────────────────────────────────────── */
      .form-control, .form-select {
        background: #FFFFFF !important;
        border-color: var(--wc-border) !important;
        color: var(--wc-dark) !important;
      }
      .form-control:focus, .form-select:focus {
        border-color: var(--wc-blue) !important;
        box-shadow: 0 0 0 2px rgba(42,57,141,0.18) !important;
      }

      /* ── Shiny notifications ───────────────────────────────────────────── */
      .shiny-notification {
        background: var(--wc-blue) !important;
        color: #FFFFFF !important;
        border-left: 3px solid var(--wc-green) !important;
        font-size: 0.88rem !important;
      }

      /* ── DT tables ─────────────────────────────────────────────────────── */
      table.dataTable thead th {
        background: var(--wc-blue) !important;
        color: #FFFFFF !important;
        font-family: 'Bebas Neue', sans-serif !important;
        letter-spacing: 0.08em !important;
        font-size: 0.9rem !important;
        border: none !important;
      }
      table.dataTable tbody td {
        color: var(--wc-dark) !important;
        border-color: var(--wc-border) !important;
        font-size: 0.88rem !important;
      }
      table.dataTable tbody tr:hover td {
        background: rgba(42,57,141,0.06) !important;
      }
      table.dataTable tbody tr.odd td  { background: #f8f9f8; }
      table.dataTable tbody tr.even td { background: #FFFFFF; }

      /* ── Admin panel ───────────────────────────────────────────────────── */
      .admin-section {
        background: rgba(180,50,50,0.05);
        border: 1px solid rgba(180,50,50,0.25);
        border-radius: 8px; padding: 1.25rem; margin-bottom: 1rem;
      }
      .admin-title {
        font-family: 'Bebas Neue', sans-serif;
        font-size: 1.2rem; color: #cc3333;
        letter-spacing: 0.08em; margin-bottom: 0.75rem;
      }

      /* ── Auth modal ────────────────────────────────────────────────────── */
      .auth-modal-overlay {
        display: none; position: fixed; inset: 0;
        background: rgba(71,74,74,0.88); z-index: 9999;
        align-items: center; justify-content: center;
      }
      .auth-modal-overlay.open { display: flex; }
      .auth-modal {
        background: #FFFFFF;
        border: 2px solid var(--wc-blue);
        border-radius: 12px; padding: 2rem; width: min(400px, 92vw);
        box-shadow: 0 20px 60px rgba(42,57,141,0.28);
      }
      .auth-modal h3 {
        font-family: 'Bebas Neue', sans-serif; font-size: 1.8rem;
        color: var(--wc-blue); letter-spacing: 0.06em; margin-bottom: 0.25rem;
      }
      .auth-modal .auth-sub {
        font-size: 0.82rem; color: var(--wc-muted); margin-bottom: 1.25rem;
      }
      .auth-tabs {
        display: flex; gap: 0; margin-bottom: 1.25rem;
        border-bottom: 1px solid var(--wc-border);
      }
      .auth-tab-btn {
        flex: 1; background: none; border: none; color: var(--wc-muted);
        font-family: 'DM Sans', sans-serif; font-size: 0.85rem;
        font-weight: 600; padding: 0.55rem; cursor: pointer;
        border-bottom: 2px solid transparent; text-transform: uppercase;
        letter-spacing: 0.08em; transition: all 0.15s;
      }
      .auth-tab-btn.active { color: var(--wc-blue); border-bottom-color: var(--wc-blue); }
      .auth-field { margin-bottom: 0.85rem; }
      .auth-field label {
        display: block; font-size: 0.75rem; color: var(--wc-muted);
        text-transform: uppercase; letter-spacing: 0.08em; margin-bottom: 0.3rem;
      }
      .auth-error   { color: #cc3333; font-size: 0.82rem; margin: 0.5rem 0; min-height: 1.1rem; }
      .auth-success { color: var(--wc-green-dark); font-size: 0.82rem; margin: 0.5rem 0; }
      .auth-footer  { font-size: 0.75rem; color: var(--wc-muted); margin-top: 1rem; text-align: center; }

      /* ── Teams ─────────────────────────────────────────────────────────── */
      .teams-section-title {
        font-family: 'Bebas Neue', sans-serif; font-size: 1.1rem;
        color: var(--wc-blue); letter-spacing: 0.08em; margin-bottom: 0.75rem;
      }
      .team-cards-row { display: flex; flex-wrap: wrap; gap: 0.75rem; margin-bottom: 0.5rem; }
      .team-card {
        background: #FFFFFF; border: 1px solid var(--wc-border);
        border-radius: 8px; padding: 0.8rem 1rem; min-width: 160px;
        display: flex; flex-direction: column; gap: 0.3rem;
        box-shadow: 0 1px 4px rgba(42,57,141,0.07);
      }
      .team-card-name { font-weight: 700; font-size: 0.92rem; color: var(--wc-blue); }
      .team-card-meta { font-size: 0.75rem; color: var(--wc-muted); }
      .team-leave-btn {
        background: transparent !important; border: 1px solid rgba(204,51,51,0.45) !important;
        color: #cc3333 !important; font-size: 0.72rem !important;
        padding: 0.2rem 0.6rem !important; margin-top: 0.35rem; align-self: flex-start;
      }
      .team-leave-btn:hover { background: rgba(204,51,51,0.1) !important; }
      .teams-input-label {
        font-size: 0.74rem; color: var(--wc-muted);
        text-transform: uppercase; letter-spacing: 0.08em; margin-bottom: 0.3rem;
      }
      .team-msg-ok  { color: var(--wc-green-dark); font-size: 0.82rem; margin-top: 0.4rem; font-weight: 600; }
      .team-msg-err { color: #cc3333;               font-size: 0.82rem; margin-top: 0.4rem; }
      .all-teams-grid { display: flex; flex-wrap: wrap; gap: 0.5rem; }
      .all-team-chip {
        background: #FFFFFF; border: 1px solid var(--wc-border);
        border-radius: 100px; padding: 0.3rem 0.85rem;
        display: flex; align-items: center; gap: 0.5rem;
      }
      .all-team-name  { font-size: 0.82rem; font-weight: 600; color: var(--wc-dark); }
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
      .lb-subtab-btn.active { color: var(--wc-blue); border-bottom-color: var(--wc-blue); }
      .lb-subtab-btn:hover  { color: var(--wc-blue-light); }
      .lb-section-title {
        font-family: 'Bebas Neue', sans-serif; font-size: 1.5rem;
        color: var(--wc-blue); letter-spacing: 0.08em; margin-bottom: 0.85rem;
      }

      /* ── Cards (bslib) ─────────────────────────────────────────────────── */
      .card {
        background: #FFFFFF !important;
        border: 1px solid var(--wc-border) !important;
        box-shadow: 0 1px 6px rgba(42,57,141,0.07);
      }
      .card-header {
        background: var(--wc-blue) !important;
        color: #FFFFFF !important;
        font-weight: 700;
      }
    "))
  ),
  
  # ── NAV PANEL: Picks ─────────────────────────────────────────────────────
  nav_panel(
    "\U0001F3DF\uFE0F Picks",
    
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
    
    # ── Auth modal ────────────────────────────────────────────────────────
    div(
      id = "auth-modal-overlay", class = "auth-modal-overlay",
      div(class = "auth-modal",
          h3("Join the Challenge"),
          div(class = "auth-sub", "Create an account or log in to save your picks"),
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
              actionButton("login_btn", "Log In \u2192",
                           class = "btn btn-wc-blue w-100", style = "margin-top:0.25rem;")
          ),
          # Register form
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
              actionButton("register_btn", "Create Account \u2192",
                           class = "btn btn-wc-blue w-100", style = "margin-top:0.25rem;")
          ),
          div(class = "auth-footer",
              "\U0001F512 Your picks are saved securely and persist across sessions.")
      )
    ),
    tags$script(HTML("
      function switchAuthTab(tab) {
        document.getElementById('auth-form-login').style.display    = tab==='login'    ? '' : 'none';
        document.getElementById('auth-form-register').style.display = tab==='register' ? '' : 'none';
        document.getElementById('auth-tab-login').classList.toggle('active',    tab==='login');
        document.getElementById('auth-tab-register').classList.toggle('active', tab==='register');
      }
      Shiny.addCustomMessageHandler('show_auth_modal', function(x) {
        document.getElementById('auth-modal-overlay').classList.add('open');
      });
      Shiny.addCustomMessageHandler('hide_auth_modal', function(x) {
        document.getElementById('auth-modal-overlay').classList.remove('open');
      });

      // ── Idle timeout: log out after 10 minutes of no activity ──────────────
      var IDLE_MS = 10 * 60 * 1000;   // 10 minutes in milliseconds
      var idleTimer = null;

      function resetIdleTimer() {
        clearTimeout(idleTimer);
        idleTimer = setTimeout(function() {
          Shiny.setInputValue('idle_timeout', true, {priority: 'event'});
        }, IDLE_MS);
      }

      // Reset on any user interaction
      ['mousemove', 'mousedown', 'keydown', 'touchstart', 'scroll', 'click']
        .forEach(function(evt) {
          document.addEventListener(evt, resetIdleTimer, true);
        });

      // Start the timer once Shiny is connected
      $(document).on('shiny:connected', function() {
        resetIdleTimer();
      });
      ")),
    tags$style(HTML("
      .chpw-modal-overlay {
        display: none; position: fixed; inset: 0;
        background: rgba(0,0,0,0.82); z-index: 9999;
        align-items: center; justify-content: center;
      }
      .chpw-modal-overlay.open { display: flex; }
      .chpw-modal {
        background: #474A4A; border: 1px solid rgba(201,168,76,0.35);
        border-radius: 12px; padding: 2rem; width: min(380px, 92vw);
        box-shadow: 0 20px 60px rgba(0,0,0,0.7);
      }
      .chpw-modal h3 {
        font-family: 'Trebuchet MS', sans-serif; font-size: 1.6rem;
        color: #2A398D; letter-spacing: 0.06em; margin-bottom: 1.25rem;
      }
    ")),
    # ── Change password modal ─────────────────────────────────────────────────
    div(
      id = "chpw-modal-overlay", class = "chpw-modal-overlay",
      div(class = "chpw-modal",
          h3("Change Password"),
          div(class = "auth-field",
              tags$label("Current password"),
              passwordInput("chpw_old",  NULL, placeholder = "Current password",   width = "100%")
          ),
          div(class = "auth-field",
              tags$label("New password"),
              passwordInput("chpw_new",  NULL, placeholder = "At least 4 characters", width = "100%")
          ),
          div(class = "auth-field",
              tags$label("Confirm new password"),
              passwordInput("chpw_new2", NULL, placeholder = "Repeat new password",  width = "100%")
          ),
          uiOutput("chpw_msg_ui"),
          div(style = "display:flex; gap:0.6rem; margin-top:0.5rem;",
              actionButton("chpw_save_btn", "Update Password",
                           class = "btn btn-wc-green", style = "flex:1;"),
              tags$button("Cancel", class = "btn btn-wc-gold", style = "flex:1;",
                          onclick = "document.getElementById('chpw-modal-overlay').classList.remove('open');")
          )
      )
    ),
    tags$script(HTML("
      Shiny.addCustomMessageHandler('show_chpw_modal', function(x) {
        document.getElementById('chpw-modal-overlay').classList.add('open');
      });
      Shiny.addCustomMessageHandler('hide_chpw_modal', function(x) {
        document.getElementById('chpw-modal-overlay').classList.remove('open');
      });
    ")),
    
    # Main tab content
    div(
      style = "max-width:1200px; margin:0 auto; padding:0 1rem;",
      tabsetPanel(
        id = "main_tabs",
        tabPanel("Group Stage",    value = "groups", uiOutput("groups_ui")),
        tabPanel("Round of 32",    value = "r32",    uiOutput("r32_ui")),
        tabPanel("Round of 16",    value = "r16",    uiOutput("r16_ui")),
        tabPanel("Quarterfinals",  value = "qf",     uiOutput("qf_ui")),
        tabPanel("Semifinals",     value = "sf",     uiOutput("sf_ui")),
        tabPanel("Final",          value = "final",  uiOutput("final_ui")),
        tabPanel("\U0001F3C6 Leaderboard", value = "lb",    uiOutput("lb_ui")),
        tabPanel("\U0001F465 My Teams",    value = "teams", uiOutput("teams_tab_ui"))
      )
    )
  ),
  
  # ── NAV PANEL: How It Works ───────────────────────────────────────────────
  nav_panel(
    "\u2139\uFE0F How It Works",
    div(style = "max-width:800px; margin:2rem auto; padding:0 1rem;",
        h2(style = "font-family:'Bebas Neue',sans-serif; color:var(--wc-blue); letter-spacing:0.06em; font-size:2rem; margin-bottom:1.5rem;",
           "How the Challenge Works"),
        layout_columns(
          col_widths = c(6, 6),
          card(card_header("1 \u00b7 Register & Log In"),
               p("Create a free account on the Picks page. Your picks are linked to your username and saved across sessions.")),
          card(card_header("2 \u00b7 Pick Match Winners"),
               p("Click a team button on any upcoming match to vote for that team. You can change your pick any time before kick-off.")),
          card(card_header("3 \u00b7 Earn Points"),
               p("Each correct prediction earns 1 point. Knockout-round picks are worth the same — simple and fair.")),
          card(card_header("4 \u00b7 Win the Challenge"),
               p("The player with the most correct picks at the end of the tournament wins. Tiebreaker: most picks in the Final."))
        ),
        br(),
        card(
          card_header("\U0001F4CA For the Group Admin"),
          p("Use the Admin panel (password-protected) to enter official results after each match.",
            "Results update scores instantly for all players."),
          p("Deploy to Posit Connect Cloud: set the ", code("WC2026_SHEET_ID"), " and ",
            code("GOOGLE_APPLICATION_CREDENTIALS"), " environment variables, then publish.")
        )
    )
  ),
  
  # ── NAV PANEL: Admin ──────────────────────────────────────────────────────
  nav_panel(
    "\U0001F512 Admin",
    div(style = "max-width:900px; margin:2rem auto; padding:0 1rem;",
        
        conditionalPanel(
          condition = "output.admin_unlocked == false",
          div(style = "text-align:center; padding:3rem 0;",
              h3(style = "font-family:'Bebas Neue',sans-serif; color:#cc3333; letter-spacing:0.08em; font-size:2rem;",
                 "Admin Access"),
              div(style = "display:flex; gap:0.6rem; justify-content:center; flex-wrap:wrap; margin-top:1rem;",
                  passwordInput("admin_pw_input", NULL, placeholder = "Password\u2026", width = "220px"),
                  actionButton("admin_unlock_btn", "Unlock", class = "btn btn-danger")
              ),
              uiOutput("admin_pw_error")
          )
        ),
        
        conditionalPanel(
          condition = "output.admin_unlocked == true",
          div(class = "admin-section",
              div(class = "admin-title", "\U0001F534 Enter Match Result"),
              layout_columns(
                col_widths = c(4, 3, 3, 2),
                selectInput("admin_match_sel",  "Match",           choices = NULL, width = "100%"),
                selectInput("admin_winner_sel", "Winner",          choices = NULL, width = "100%"),
                textInput("admin_score_inp",    "Score (e.g. 2-1)", placeholder = "2-1", width = "100%"),
                div(style = "padding-top:1.65rem;",
                    actionButton("admin_save_btn", "Save Result", class = "btn btn-danger w-100"))
              ),
              uiOutput("admin_save_status")
          ),
          div(class = "admin-section",
              div(class = "admin-title", "\U0001F4CB All Votes"),
              DT::dataTableOutput("admin_votes_table")
          ),
          div(class = "admin-section",
              div(class = "admin-title", "\U0001F4CA Results Entered"),
              DT::dataTableOutput("admin_results_table")
          ),
          div(style = "margin-bottom:2rem;",
              downloadButton("admin_dl_btn", "\u2B07 Download Votes CSV",
                             class = "btn btn-wc-outline")
          )
        )
    )
  ),
  
  nav_spacer(),
  nav_item(
    tags$small(style = "color:rgba(255,255,255,0.6); padding:0 0.75rem;",
               "Jun 11 – Jul 19, 2026")
  )
)
