# Novice — Flutter × Landing Page Integration Guide

## Architecture

```
web/
  index.html       ← Entry point. Loads landing.html in an iframe + Flutter overlay
  landing.html     ← Blended landing page (HTML design + Flutter dark theme)
  app.html         ← Flutter web shell (bootstraps main.dart.js)
  favicon.svg      ← SVG favicon

lib/
  main.dart                          ← Flutter app entry (unchanged)
  core/
    theme/app_theme.dart             ★ UPDATED — unified token system
    router/app_router.dart           ★ UPDATED — clean imports
  features/
    splash/splash_screen.dart        ★ UPDATED — mint accent, icon logo
    home/home_screen.dart            ★ UPDATED — module chips, stat cards, redesigned
    demo/demo_screen.dart            ★ UPDATED — all 5 modules, tab bar, step system
    training/training_screen.dart    (unchanged — camera HUD is already dark/mint)
    results/results_screen.dart      (unchanged)
    history/history_screen.dart      (unchanged)
    settings/settings_screen.dart    (unchanged)
    research/                        (unchanged — research flows)
```

## Design Tokens (HTML ↔ Flutter parity)

| Token        | CSS variable  | Flutter constant         | Value       |
|-------------|---------------|--------------------------|-------------|
| Background  | `--bg`        | `AppTheme.bg`            | `#0A0D0F`   |
| Surface     | `--surface`   | `AppTheme.surface`       | `#111518`   |
| Card        | `--card`      | `AppTheme.card`          | `#161C20`   |
| Border      | `--border`    | `AppTheme.border`        | `#FFFFFF14` |
| Mint        | `--mint`      | `AppTheme.accent`        | `#00E5A0`   |
| Coral       | `--coral`     | `AppTheme.accentWarn`    | `#FF4D6D`   |
| Amber       | `--amber`     | `AppTheme.accentAmber`   | `#FFC947`   |
| CPR Red     | `--red`       | `AppTheme.cprRed`        | `#C84B25`   |
| Choking     | `--amberM`    | `AppTheme.chokingAmber`  | `#A8660E`   |
| Stroke      | `--purple`    | `AppTheme.strokePurple`  | `#4840A8`   |
| Recovery    | `--teal`      | `AppTheme.recoveryTeal`  | `#0F9070`   |
| AED Blue    | `--blue`      | `AppTheme.aedBlue`       | `#2B7FD4`   |

## How the Bridge Works

1. User visits `index.html` → sees `landing.html` in full-screen iframe
2. Any CTA button (e.g. "Start CPR training") calls `window.sendPrompt(action)`
3. `landing.html` delegates up to `index.html`'s `sendPrompt()` via `window.parent`
4. `index.html` maps the action string to a Flutter route and opens the overlay
5. The overlay slides up from the bottom carrying `app.html` in an iframe
6. `app.html` converts the hash fragment to a URL path for GoRouter
7. Flutter loads and navigates to the correct screen
8. The overlay topbar has a ✕ close button that slides the panel back down

## Building for Production

```bash
# Build Flutter web to web/build/
flutter build web --release --base-href /

# Copy Flutter build outputs into the web/ folder
cp -r build/web/* web/

# Serve
python3 -m http.server 8080 --directory web/
# Visit http://localhost:8080
```

## Development

```bash
# Run Flutter web dev server on port 5000
flutter run -d chrome --web-port 5000

# Then open web/index.html in a browser — update app.html src to http://localhost:5000
# for dev-mode hot reload, or serve everything from Flutter's dev server.
```

## sendPrompt Action Vocabulary

| Action string                          | Flutter route   |
|----------------------------------------|-----------------|
| `Open CPR training mode`               | `/participant`  |
| `View my results`                      | `/history`      |
| `Open bleeding control module`         | `/demo`         |
| `Open burns module`                    | `/demo`         |
| `Open fractures module`                | `/demo`         |
| `Open diabetic emergency module`       | `/demo`         |
| `Open anaphylaxis module`              | `/demo`         |
| `Open mental health first aid module`  | `/demo`         |

## License
GNU General Public License v3.0 — Jean Robert Gatwaza, African Leadership University 2024
