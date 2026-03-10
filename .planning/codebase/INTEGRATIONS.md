# External Integrations

**Analysis Date:** 2026-03-10

## APIs & External Services

**Not detected.**

The codebase contains no HTTP requests, REST API calls, or external service integrations. All functionality is self-contained within the Godot engine.

## Data Storage

**Databases:**
- Not applicable - No database integration detected

**File Storage:**
- Local filesystem only
  - Asset storage: `art/`, `music/`, `animations/`, `scenes/`, `components/`
  - Game data: Stored as Godot `.tscn` scene files and `.gd` script files
  - `.godot/` directory: Generated cache, git-ignored

**Caching:**
- Not applicable

## Authentication & Identity

**Auth Provider:**
- Not applicable - No authentication system implemented

**Implementation:**
- No user accounts, login, or authorization system

## Monitoring & Observability

**Error Tracking:**
- Not applicable

**Logs:**
- Console output only via Godot's built-in print/debug logging
- Test framework logging: GUT test runner produces `test_results.xml` output

## CI/CD & Deployment

**Hosting:**
- Not applicable - Desktop game (runs locally)

**CI Pipeline:**
- GitHub Actions (`.github/workflows/ci.yml`)
  - Lint job: Runs `gdlint` and `gdformat --check` on all `.gd` files
  - Test job: Runs GUT unit tests via `make test` in headless mode
  - Test artifact: Uploads `test_results.xml` to GitHub

## Environment Configuration

**Required env vars:**
- None - Project uses Godot's Inspector-based configuration (@export variables)

**Secrets location:**
- Not applicable - No secrets or credentials in use

## Webhooks & Callbacks

**Incoming:**
- Not applicable

**Outgoing:**
- Not applicable

## Audio Assets

**Format:**
- WAV files preloaded via `preload()` in `scripts/background_music.gd`
- Location: `music/`
  - `home.wav` (14 MB)
  - `dark_woodslands.wav` (22 MB)

**Integration:**
- Godot `AudioStreamPlayer` node
- Singleton autoload: `BackgroundMusic` (registered in `project.godot` as `scenes/background_music.tscn`)
- Triggered via signals when player enters area detection zones

---

*Integration audit: 2026-03-10*
