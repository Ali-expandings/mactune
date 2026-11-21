# Changelog

All notable changes to MacTune are documented here.
Format: [Keep a Changelog](https://keepachangelog.com/) · Versioning: [SemVer](https://semver.org/).

## [2.1.0] — 2026-11-21

The "read what macOS already wrote down" release. macOS keeps detailed records of what went wrong (memory kills, resource hogs, crashes). This release reads more of them, reads them more carefully, and fixes places where v2.0 drew the wrong conclusion. Thanks to everyone who pushed back in the launch threads, and to @yyouretoast for PR #2.

### Added
- **Memory-kill culprit**: each JetsamEvent report records the biggest memory user at the moment RAM ran out; MacTune now names it ("2026-11-19 17:23: biggest memory user when RAM ran out: java") and uses it in the closing advice
- **macOS's own resource-hog reports**: when a process blows through its CPU, disk-write or wakeup budget, macOS writes a `.diag` report. The newest five are listed in plain terms ("Google Chrome: wrote 8.4 GB to disk in 19 min"), with macOS components labelled. Read-only, no score penalty
- **App database (LaunchServices) bloat**: counts registrations that point at apps that no longer exist. In-place app updates and deleted installers pile these up, and every new registration rewrites the whole database, so a bloated one becomes constant disk writes by `lsd`. On the author's Mac: 1,110 of 2,422 entries were dead and `lsd` wrote 2.1 GB in 83 minutes. Entries on `/Volumes` are skipped (an unplugged drive isn't a dead app)
- **App database cleanup** (opt-in, one-way, only when bloat is measured): unregisters entries whose app is gone, then compacts the database. Installed apps and default-app choices are untouched
- **Memory compressor sample**: the live swap sample now also reads compressions per second; heavy compressor churn is flagged even when swap looks quiet
- **SMART on every physical disk**, not just `disk0` (adapted from PR #2: synthesized APFS containers and "Not Supported" USB enclosures are skipped so nothing prints twice)
- CI: dry-run-claims-nothing check, history trend across two runs, `--reset`, and installer argument checks

### Fixed
- **Battery wording**: v2.0 said any battery under 80% "may cap peak power". That's only true of a *failing* battery (condition not Normal); an old battery with a Normal condition still delivers full power and just holds less charge. A reader called this out on Reddit, and the wording now follows the condition, not the age
- **Crash count included things that aren't crashes**: memory-kill reports and non-fatal fault reports (`ExcUserFault_`, `ExcResource_`) were counted as crashes. On the author's Mac that turned 13 crashes into 16
- **"Reinstall it" advice for parts of macOS**: Apple processes that aren't named `com.apple.*` (Rosetta's `oahd-helper`, `lsd`) were treated as third-party apps. The crash report's executable path now decides: system locations mean a macOS component, which gets restart advice instead
- **Open apps counted as background services**: `launchctl list` includes every running app (`application.…`); those are no longer counted (18 → 13 on the author's Mac)
- **Dry run printed success lines** ("✓ npm cache → Trash (338.6 MB reclaimed)", "✓ Homebrew cleaned up") for things it didn't do. Dry runs now show only `[dry-run]` lines and reclaim nothing (cache part reported in PR #2)
- **Kernel panics written as `.panic` files** were never scanned; both `.ips` and `.panic` are read now
- **Swap sample reported pages as "per sec"**; it now reports KB using the machine's real page size (PR #2)
- **Broken login agents**: the plist goes to Trash only if launchd actually unloaded it (PR #2)
- `run()` now reports a failing command instead of following it with a ✓ (PR #2)
- Saved-answers keys are matched literally, not as a regex (PR #2); the history trend only reads whole-number scores (PR #2)
- `install.sh --prefix` with no directory now exits with an error instead of crashing (PR #2)

### Not taken from PR #2, and why
- Reading only the first 5 lines of each report to find memory kills: a JetsamEvent report's first lines never contain the word "jetsam", so this found 0 events where v2.0 finds them
- Pinning a SHA-256 of `main` in `install.sh`: the installer downloads `main`, so every commit that forgot the hash would break the curl install. Installing from a release tag with its hash would be the sounder way to do this
- The saved-answers CI test: a dry run never writes saved answers by design, so the test could not pass

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
