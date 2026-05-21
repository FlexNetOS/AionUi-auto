# Zero-upstream-touch contract

This fork (`FlexNetOS/AionUi-auto`) maintains a hard invariant: **every file
that exists in upstream `iOfficeAI/AionUi:main` is byte-identical between
upstream and this fork's `develop` branch.** All FlexNetOS additions live in
two namespaces that upstream never touches:

- `flexnetos/` — code (shell, scripts, eventually TypeScript addons)
- `.aionui-data/` — runtime config + git-tracked seed templates

## Why this contract exists

`.github/workflows/sync-upstream.yml` mirrors `upstream/main` into our `main`
every six hours, then `promote-main-to-develop.yml` either fast-forward-merges
or opens a PR. If any upstream-owned file diverges, every six-hour sync risks
a merge conflict — for the lifetime of the fork.

By keeping divergence to literally zero on upstream-owned paths, sync is
**conflict-free forever** (modulo the negligibly small chance of upstream
adding a new file under a path we also use; see _Edge cases_ below).

## What "upstream-owned" means

A path is upstream-owned if it exists in `upstream/main` at any commit.
Concretely, the following paths and everything beneath them are off-limits
for FlexNetOS modification:

- All of `src/`, `tests/`, `scripts/`, `resources/`, `mobile/`,
  `homebrew/`, `public/`, `examples/`, `package/`, `patches/`
- The whole of `docs/` (except `docs/FORK_WORKFLOW.md`, which is a new file
  we added — see allowlist below)
- All root-level dotfiles owned by upstream (`.gitignore`,
  `.dockerignore`, `.codecov.yml`, `.npmrc`, `.oxfmtrc.json`,
  `.oxlintrc.json`, `.pre-commit-config.yaml`, `.prettierignore`,
  `.prettierrc.json`, `.gitattributes`, `.husky/`)
- All root-level config files (`package.json`, `bun.lock`,
  `electron.vite.config.ts`, `electron-builder.yml`, `tsconfig.json`,
  `vitest.config.ts`, `uno.config.ts`, etc.)
- All files in `.github/` _except_ the additive workflows we created
  (`sync-upstream.yml`, `promote-main-to-develop.yml`)

## What FlexNetOS owns (allowlist)

- `flexnetos/**` — created in this fork, never present upstream
- `.aionui-data/**` — created in this fork, never present upstream
- `.github/workflows/sync-upstream.yml` — additive workflow
- `.github/workflows/promote-main-to-develop.yml` — additive workflow
- `docs/FORK_WORKFLOW.md` — additive doc under upstream's `docs/`

> `docs/FORK_WORKFLOW.md` is the one place we add a file beneath an
> upstream-owned directory. The cost is that a strict `git diff upstream/main
-- docs/` would show one added file. The proof script compensates with the
> `:!docs/FORK_WORKFLOW.md` pathspec exclusion before declaring contract held.

## Mechanical verification

The contract holds if **all seven** checks pass:

| #   | Check                                                  | How                                                                                                                                                                                            |
| --- | ------------------------------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------ |
| 1   | No modifications under upstream-owned paths            | `git diff upstream/main -- . ':!flexnetos' ':!.aionui-data' ':!.github/workflows/sync-upstream.yml' ':!.github/workflows/promote-main-to-develop.yml' ':!docs/FORK_WORKFLOW.md'` returns empty |
| 2   | `package.json` + `bun.lock` byte-identical to upstream | sha256 of each matches `git show upstream/main:<file>`                                                                                                                                         |
| 3   | Lint baseline preserved                                | `bun run lint` → 0 errors / 1884 warnings                                                                                                                                                      |
| 4   | TypeCheck passes                                       | `bunx tsc --noEmit` exits 0                                                                                                                                                                    |
| 5   | Test suite passes                                      | `bun run test` → 4528 passed / 0 failed                                                                                                                                                        |
| 6   | `package.json` `.scripts` keys unchanged               | `jq -c '.scripts                                                                                                                                                                               | keys' package.json` byte-identical to upstream's |
| 7   | App launches in dev mode and writes to `.aionui-data/` | smoke test confirms a Chromium-owned artifact appears inside `.aionui-data/` after `flexnetos/launch/run-in-place.sh`                                                                          |

`flexnetos/docs/INSTALL_PROOF.md` contains the most recent passing run of all
seven checks, with command outputs verbatim.

## Edge cases

**Upstream adds a `flexnetos/` directory.** Vanishingly unlikely (the name is
specific to this fork). If it ever happens, we rename our directory and update
the wrapper script. One-time cost.

**Upstream renames an existing file we depend on** (e.g. moves
`src/process/utils/configureChromium.ts`). Not a contract violation — we don't
modify that file. The wrapper's `XDG_CONFIG_HOME` redirect still works because
it operates at the OS environment level, not at the source level.

**Upstream drops `bun` and switches to another package manager.** The wrapper
uses `bun` directly. If upstream drops bun, we update the wrapper. Still no
contract violation — `flexnetos/launch/run-in-place.sh` is FlexNetOS-owned.

**Upstream adds `.aionui-data` to its own `.gitignore` for unrelated reasons.**
No effect on us. Our nested `.aionui-data/.gitignore` covers the runtime
artifacts inside it; the upstream rule, if it existed, would just be redundant.

## How to evolve this contract

If, after deliberation, a future feature genuinely requires modifying an
upstream-owned file:

1. Open an issue in this fork's repo titled `contract: propose <file> exemption`.
2. Document the feature and why no addon-shaped alternative works.
3. Update this file with the new exemption and the proof script's allowlist
   before merging the change.
4. Accept that every upstream sync from that point forward will potentially
   conflict on that file.

The contract is meant to be broken deliberately, not by accident. Document
before, not after.
