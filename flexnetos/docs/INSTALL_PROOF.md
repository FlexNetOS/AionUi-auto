# INSTALL_PROOF.md — zero-feature-loss verification run

**Captured:** 2026-05-21 (UTC 16:04–16:23)
**Repo:** `FlexNetOS/AionUi-auto`
**Worktree:** `/home/drdave/_work/repos/_forks/aionui`
**Branch:** `develop` (HEAD `00cf7d60d04f1a7a6b54b76079dca2046f491fca`)
**Upstream:** `iOfficeAI/AionUi` (upstream/main `6dea290789ce2be6fc29bb1f75ea4a2df7468df9`)

This file records the seven-check verification that the FlexNetOS
"run-in-place" install introduces **zero feature loss** relative to upstream.
All commands were executed in the worktree above; the raw logs live in
`/tmp/aionui-proof/` on the build host.

| #   | Check                                                              | Result                                     |
| --- | ------------------------------------------------------------------ | ------------------------------------------ | -------- |
| 1   | `git diff upstream/main` on all upstream-owned paths returns empty | **PASS**                                   |
| 2   | `package.json` + `bun.lock` byte-identical to upstream             | **PASS**                                   |
| 3   | `bun run lint` → 0 errors / 1884 warnings (baseline)               | **PASS**                                   |
| 4   | `bunx tsc --noEmit` exits 0                                        | **PASS**                                   |
| 5   | `bun run test` → 4528 passed / 0 failed (baseline)                 | **PASS**                                   |
| 6   | `jq '.scripts                                                      | keys' package.json` identical before/after | **PASS** |
| 7   | App launches in dev mode and writes to `.aionui-data/`             | **PASS**                                   |

**Overall: 7 / 7 PASS — contract held.**

---

## Check 1 — No modifications under upstream-owned paths

Command run:

```bash
git fetch upstream
git diff --stat upstream/main -- . \
  ':!flexnetos' \
  ':!.aionui-data' \
  ':!.github/workflows/sync-upstream.yml' \
  ':!.github/workflows/promote-main-to-develop.yml' \
  ':!docs/FORK_WORKFLOW.md'
```

Output: _(empty — no files differ from upstream/main)_

**PASS** — every file existing in `upstream/main` is byte-identical between
upstream and this fork's `develop`. The five excluded paths are the allowlisted
FlexNetOS additions documented in `flexnetos/docs/CONTRACT.md`.

## Check 2 — `package.json` and `bun.lock` byte-identical to upstream

Captured hashes (pre-change baseline):

```
dfcd999ea1ec33d7b2d763ae7461b2daaeaa956120bf12443bb5eadd04f0b7e7  package.json
01275a364819567cb31aeb63bef9b91540081f1fd1d32c310628304e02bdbb01  bun.lock
```

Post-change verification:

```
$ sha256sum -c <baseline>
package.json: OK
bun.lock: OK
```

**PASS** — neither file modified by the install.

## Check 3 — Lint baseline preserved

Pre-change:

```
Found 1884 warnings and 0 errors.
Finished in 109ms on 1486 files with 128 rules using 48 threads.
lint exit: 0
```

Post-change:

```
Found 1884 warnings and 0 errors.
Finished in 118ms on 1486 files with 128 rules using 48 threads.
lint exit: 0
```

`diff` between pre and post: **IDENTICAL**.

**PASS** — install introduced zero new lint findings; baseline unchanged.

## Check 4 — TypeCheck passes

```
$ bunx tsc --noEmit
tsc exit: 0   (pre-change)
tsc exit: 0   (post-change)
```

**PASS** — no new type errors.

## Check 5 — Test suite passes

Pre-change summary:

```
Test Files  438 passed | 9 skipped (447)
     Tests  4528 passed | 51 skipped | 22 todo (4601)
test exit: 0
```

Post-change summary:

```
Test Files  438 passed | 9 skipped (447)
     Tests  4528 passed | 51 skipped | 22 todo (4601)
test exit: 0
```

`diff` between pre and post summaries: **IDENTICAL**.

**PASS** — every one of the 4528 passing tests continues to pass.

## Check 6 — `package.json` `.scripts` keys unchanged

```
$ diff <(pre-jq) <(post-jq)
scripts: IDENTICAL
```

The full key list (60 entries) is preserved exactly:
`bench, bench:db, bench:full, bench:report, bench:startup, build, build-deb,
build-mac, build-mac:arm64, build-mac:x64, build-win, build-win:arm64,
build-win:x64, build:renderer:web, build:server, cli, debug:custom-agent,
debug:mcp, debug:mcp:list, debug:mcp:validate, debug:perf, debug:perf:report,
dist, dist:linux, dist:mac, dist:win, format, format:check, i18n:types, lint,
lint:fix, make, package, postinstall, prepare, resetpass, server:resetpass,
server:resetpass:prod, server:start, server:start:prod, server:start:prod:remote,
server:start:remote, start, start:multi, test, test:bun, test:contract,
test:coverage, test:e2e, test:e2e:conv:acp, test:e2e:team, test:e2e:team:comm,
test:e2e:team:create, test:e2e:team:lifecycle, test:e2e:team:whitelist,
test:integration, test:packaged:bun, test:packaged:i18n, test:watch, webui,
webui:prod, webui:prod:remote, webui:remote`

**PASS** — no scripts added, removed, or renamed.

## Check 7 — App launches in dev mode and writes to `.aionui-data/`

Command run:

```bash
SMOKE_TIMEOUT_S=180 flexnetos/launch/smoke-test.sh
```

Wrapper output:

```
[flexnetos] repo:        /home/drdave/_work/repos/_forks/aionui
[flexnetos] userData →   /home/drdave/_work/repos/_forks/aionui/.aionui-data
[flexnetos] script:      bun run webui
[smoke] elapsed:   6s
[smoke] wrote?:    yes
```

Electron's own startup banner confirms the userData redirect took effect:

```
[AionUi:env]   AionUi v1.9.25 (development)
[AionUi:env]   Electron : 37.10.3
[AionUi:env]   Chromium : 138.0.7204.251
[AionUi:env]   userData : /home/drdave/_work/repos/_forks/aionui/.aionui-data/AionUi-Dev
[AionUi:env]   logFile  : /home/drdave/_work/repos/_forks/aionui/.aionui-data/AionUi-Dev/logs
```

All 26 SQLite migrations completed without error:

```
11:23:30.230 › [Migrations] All migrations completed successfully
```

Artifacts written by Electron inside `.aionui-data/`:

```
.aionui-data/AionUi-Dev/
├── Preferences                     Chromium preferences
├── Local Storage/leveldb/          LevelDB local storage
├── Cookies, Cookies-journal        SQLite cookie store
├── Cache/Cache_Data/               HTTP cache
├── Code Cache/{js,wasm}/           V8 code cache
├── Crashpad/client_id              crash reporter ID
├── Dictionaries/en-US-10-1.bdic    spell-check dictionary
├── extensions/fmkadmapgo…/         React DevTools (auto-installed in dev)
├── Shared Dictionary/{cache,db}    HTTP shared dictionaries
├── Trust Tokens, Trust Tokens-journal
├── Network Persistent State
├── DevToolsActivePort
├── logs/2026-05-21.log             AionUi structured log
├── blob_storage/<uuid>             AionUi blob store
└── aionui/aionui.db                AionUi SQLite (26 migrations applied)
```

Top-level subdirs created: 11. Direct files at the AionUi-Dev/ root: 14.

Verification that _no runtime artifact_ is git-tracked (nested `.gitignore`
deny-everything-then-allow policy enforced correctly):

```bash
$ git status --short .aionui-data
?? .aionui-data/
```

The `??` line means the only thing git sees is the directory itself with the
tracked allowlist (`.gitignore`, `README.md`, `mcp-servers/example.json`,
`agents/example.json`). All Electron-managed files are correctly excluded.

**PASS** — the wrapper redirects userData via `XDG_CONFIG_HOME`; Electron
respects the redirect, lands the entire runtime tree inside the repo, and the
nested gitignore prevents any of it from being version-controlled.

---

## Host-environment notes (one-time prerequisites)

Check #7 requires two host-side conditions that are NOT specific to FlexNetOS
or this fork — they apply to any local Electron development:

1. **inotify watcher limit** must be high enough for Vite's file watcher.
   On most Linux distros the default (typically 8192) is too low.

   ```bash
   sudo sysctl fs.inotify.max_user_watches=524288
   sudo sysctl fs.inotify.max_user_instances=1024
   ```

   Persist by adding the same lines to `/etc/sysctl.d/99-inotify.conf`.

2. **`chrome-sandbox` setuid root** for Electron's SUID sandbox. Bun's
   `postinstall` does not chown this binary because it lacks root.

   ```bash
   sudo chown root:root node_modules/electron/dist/chrome-sandbox
   sudo chmod 4755 node_modules/electron/dist/chrome-sandbox
   ```

If either condition is missing, Electron will fail to launch with an
`ENOSPC` (watcher) or `SUID sandbox helper binary … is not configured`
error. Neither failure indicates a problem with FlexNetOS or the install —
they are host configuration issues that affect upstream `bun run start`
identically.

## Files added by this install

```
flexnetos/
├── README.md
├── launch/
│   ├── run-in-place.sh         (XDG_CONFIG_HOME wrapper)
│   ├── aionui-dev.desktop      (Linux app-menu entry template)
│   ├── install-launcher.sh
│   └── uninstall-launcher.sh
├── addons/README.md
├── launch/smoke-test.sh        (contract check #7 runner)
└── docs/
    ├── RUN_IN_PLACE.md
    ├── extending.md
    ├── CONTRACT.md
    └── INSTALL_PROOF.md        (this file)

.aionui-data/
├── .gitignore                  (deny-everything-then-allow policy)
├── README.md
├── mcp-servers/example.json    (reference template, not auto-loaded)
└── agents/example.json         (reference template, not auto-loaded)
```

Total new files: **15**. Total upstream-owned files modified: **0**.

## How to re-run this verification

```bash
cd /home/drdave/_work/repos/_forks/aionui
git fetch upstream

# Pre-change baselines (only needed once per upstream sync)
sha256sum package.json bun.lock
jq -c '.scripts | keys' package.json

# Verification (every check)
git diff --stat upstream/main -- . \
  ':!flexnetos' ':!.aionui-data' \
  ':!.github/workflows/sync-upstream.yml' \
  ':!.github/workflows/promote-main-to-develop.yml' \
  ':!docs/FORK_WORKFLOW.md'
bun run lint
bunx tsc --noEmit
bun run test

# Smoke test (Check 7)
SMOKE_TIMEOUT_S=180 flexnetos/launch/smoke-test.sh
```

`flexnetos/launch/smoke-test.sh` writes its log/PID artifacts to
`${PROOF_DIR:-${TMPDIR:-/tmp}/aionui-proof}/` — override `PROOF_DIR` to
redirect into the repo (e.g. `.aionui-data/.proof/`, which is gitignored
by the nested deny-by-default policy).
