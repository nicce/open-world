# External Integrations

**Analysis Date:** 2025-01-24

## APIs & External Services

**Not detected:**
- The project is a self-contained Godot game. No external SaaS APIs or cloud services are currently used.

## Data Storage

**Databases:**
- **Local Filesystem:** Used for game saves.
  - Client: `SaveManager` (autoload) at `res://scripts/save_manager.gd`.
  - Format: JSON files stored in the user data directory.

**File Storage:**
- **Local Filesystem:** Resources (textures, sounds, scripts) are packed into the exported executable.

**Caching:**
- **None:** No explicit caching system outside of Godot's internal resource loader.

## Authentication & Identity

**Auth Provider:**
- **Custom:** No authentication is currently implemented. The game is single-player and uses local saves.

## Monitoring & Observability

**Error Tracking:**
- **None:** No external tools like Sentry or New Relic are integrated.
- **Godot Debugger:** Standard error/warning output is used during development.

**Logs:**
- **Console:** Godot's `print()` and `printerr()` are used for logging. Output is captured in `test_results.xml` during testing.

## CI/CD & Deployment

**Hosting:**
- **Not configured:** No automated deployment to platforms like itch.io or Steam detected.

**CI Pipeline:**
- **GitHub Actions:** CI workflow is defined in `.github/workflows/ci.yml`. It runs tests and linting.
  - Runners: `ubuntu-latest`.
  - Tools: GUT, gdlint.

## Environment Configuration

**Required env vars:**
- **None:** All configuration is handled within `project.godot`.

**Secrets location:**
- **Not applicable:** No secrets are currently required.

## Webhooks & Callbacks

**Incoming:**
- **None**

**Outgoing:**
- **None**

---

*Integration audit: 2025-01-24*
