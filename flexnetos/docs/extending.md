# Extending AionUi without touching upstream

This document is a recipe book for adding FlexNetOS features in ways that
preserve the zero-upstream-touch contract (`flexnetos/docs/CONTRACT.md`).
Every recipe below ends with the same verification: `git diff upstream/main`
on every upstream-owned path returns empty.

## Recipe 1 — Add an MCP server

AionUi reads MCP server definitions from its userData directory. With the
`run-in-place.sh` wrapper, that becomes `.aionui-data/<appName>/mcp-servers/`
at runtime, but the human-authored seed lives at `.aionui-data/mcp-servers/`
so it is git-tracked.

```bash
# 1. Copy the template.
cp .aionui-data/mcp-servers/example.json .aionui-data/mcp-servers/my-server.json

# 2. Edit fields: command, args, env. See template for the schema.
$EDITOR .aionui-data/mcp-servers/my-server.json

# 3. Restart AionUi; the server appears in Settings → MCP.
flexnetos/launch/run-in-place.sh
```

## Recipe 2 — Add a custom agent

```bash
cp .aionui-data/agents/example.json .aionui-data/agents/my-agent.json
$EDITOR .aionui-data/agents/my-agent.json
flexnetos/launch/run-in-place.sh
```

Agents appear in the chat picker under the name set in the JSON file.

## Recipe 3 — Add a launcher subcommand

Edit `flexnetos/launch/run-in-place.sh` directly — it lives in a FlexNetOS-owned
file, so changes are conflict-free. The wrapper already handles `--webui` and
`--mode <script>`; extend the `case` block for new behaviors.

## Recipe 4 — Add a wholly new addon (TypeScript / shell / Node)

Put it under `flexnetos/addons/<your-addon>/`. Each addon owns its own
`README.md`, its own dependencies (a local `package.json` is allowed and
encouraged so addons can have their own toolchain pinned), and its own
entry point.

The repo-wide `bun.lock` and root `package.json` remain untouched.

## Recipe 5 — Patch a node_modules dependency

Use `patch-package` via the existing `patches/` directory (already part of
upstream's workflow). `patch-package` survives `bun install` and re-applies
on every CI run, so the patch is durable without touching `package.json`.

```bash
# After editing files inside node_modules/<pkg>:
npx patch-package <pkg>
git add patches/<pkg>+<version>.patch
```

The `postinstall` script already runs `patch-package` (see upstream's
`scripts/postinstall.js`).

## Recipe 6 — Need to actually modify upstream source

You can't, by contract. If a feature genuinely requires editing `src/` or
`tests/`, your options are:

1. Open an upstream PR at `iOfficeAI/AionUi` and wait for the merge.
2. Vendor the change as a `patches/` entry via `patch-package` on a
   compiled artifact — only works for npm-package files, not in-repo
   source files.
3. Express the feature as a sidecar process under `flexnetos/addons/`
   that talks to AionUi over IPC / MCP / HTTP.

Option 3 is almost always tractable. AionUi exposes a CDP port and an MCP
server interface; most "feature" requests fit cleanly into an addon that
consumes those.

## Verification

After any of the above, run the proof script (or the manual sequence) and
confirm:

```bash
git fetch upstream
git diff --stat upstream/main -- . ':!flexnetos' ':!.aionui-data' \
  ':!.github/workflows/sync-upstream.yml' \
  ':!.github/workflows/promote-main-to-develop.yml' \
  ':!docs/FORK_WORKFLOW.md'
#   → 0 files changed, 0 insertions(+), 0 deletions(-)

bun run lint                          # 0 errors, 1884 warnings
bunx tsc --noEmit                     # exit 0
bun run test                          # 4528 passed, 0 failed
```

All checks pass → the contract holds. See `flexnetos/docs/INSTALL_PROOF.md`
for the most recent automated proof run.
