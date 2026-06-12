# Changelog

All notable changes to MacTune are documented here.
Format: [Keep a Changelog](https://keepachangelog.com/) · Versioning: [SemVer](https://semver.org/).

## [2.0.0] — 2026-06-12

The "deep diagnosis" release. The value of a universal tool concentrates in what it can measure — so this release measures much more, and scores it.

### Added
- **Health score 0–100 with letter grade** — every penalty traceable to a measurement; reasons printed under the grade
- **Score history & trend** — each run appends to `~/.config/mactune/history.csv`; the next run shows the delta
- **Memory by app** — RSS summed across all helper processes per app bundle (a browser is 30+ processes; per-process lists undercount the real owners)
- **Jetsam detection** — flags when macOS force-killed processes for memory in the last 7 days
- **Crash & kernel-panic scan** — last 7 days of DiagnosticReports; most frequent crasher named; Apple-component crashers get restart advice instead of "reinstall"
- **Disk SMART status** — a dying disk is the slowdown nobody checks for; failing → back-up-now warning
- **Battery health** (laptops) — capacity %, cycle count, condition; aged batteries quietly cap performance
- **Disk hotspot map** — where the space went: Trash, Downloads, user caches, iPhone/iPad backups, Docker disk image, Xcode DerivedData (only entries >1 GB)
- **Uptime check** — restart-overdue flag at 14+ days (Apple's own first fix)
- **"Slow right now" detection** — Spotlight indexing in progress, Time Machine backup running, WindowServer load ≥25%
- **Third-party background service count** via `launchctl`
- **Apple Silicon thermal sampling** — real `powermetrics` reading in the admin section instead of "not queryable"
- **Optional network test** — Apple's `networkQuality` (macOS 12+), because half of "my Mac is slow" is the internet
- **Expanded developer caches** — npm, Xcode DerivedData, pip, Yarn, pnpm, Cargo; threshold-gated, opt-in, moved to Trash whole (recoverable, unlike one-way `clean` commands)
- **Reclaimed-space tally** shown in the closing summary
- **CLI flags** — `--dry-run`, `--yes`, `--no-sudo`, `--rollback`, `--reset`, `--version`, `--help`

### Fixed
- **"Top 5 by RAM" was never sorted by RAM** — `ps -r` sorts by CPU; the list could show a 26 MB process as #1 while the true top consumed 280 MB. Replaced by per-app aggregation
- **Zero-count crash math** — `grep -c` prints `0` *and* exits non-zero on no matches; the `|| echo 0` fallback produced `"0\n0"` and an integer-expression error

## [1.x] — 2026-06-10

Initial tool: machine profile, diagnosis (memory pressure, swap rate, disk, Intel thermals, login items, top processes), safe maintenance (broken login agents, QuickLook, DNS), opt-in npm/brew cleanup, opt-in UI performance mode with rollback, gated admin section (snapshot thinning, pressure-gated purge, measured Spotlight reindex, Low Power Mode), platform notes, saved-answers profile, sticky progress bar.

Hardened by adversarial review; every confirmed finding fixed (Apple Silicon thermal honesty, reversibility claims, modern Reduce-Motion domain, snapshot-thinning gating, `cfprefsd` resurrection bug in rollback).
