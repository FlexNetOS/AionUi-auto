# .aionui-data/

Runtime config + state directory for AionUi when launched via the FlexNetOS
`run-in-place.sh` wrapper. The wrapper sets `XDG_CONFIG_HOME` to this
directory, so Electron resolves its userData root here instead of
`~/.config/`.

## What's tracked vs. ignored

The nested `.gitignore` in this directory uses a **deny-everything-then-allow**
policy. Only the following are git-tracked:

| Path                 | Purpose                                          |
| -------------------- | ------------------------------------------------ |
| `.gitignore`         | the policy itself                                |
| `README.md`          | this file                                        |
| `mcp-servers/*.json` | reference templates for MCP server configs       |
| `agents/*.json`      | reference templates for custom ACP agent configs |

Everything else — `AionUi/`, `AionUi-Dev/`, `Local Storage/`, `IndexedDB/`,
`GPUCache/`, `Cookies`, `Network/`, `DawnCache/`, conversation history,
session storage, logs, caches, secrets — is automatically excluded. Any
new Electron-managed subdirectory introduced by a future Chromium upgrade
inherits the deny rule for free; no `.gitignore` maintenance needed.

## How the templates are used (honest version)

AionUi reads MCP server definitions from `ProcessConfig.get('mcp.config')`
(stored inside `electron-store` under `userData/`) and custom ACP agent
definitions from `ProcessConfig.get('acp.customAgents')`. **Neither is
auto-loaded from a directory on disk.**

So the committed templates here are:

1. **Reference documentation** — the JSON shows the exact schema fields
   (`id`, `name`, `transport`, etc.) the app expects.
2. **Source of truth** — "these are the MCP servers / agents the FlexNetOS
   AionUi deployment should have configured." Git-tracked, reviewable,
   diff-able across the team.
3. **Import targets** — copy-paste the JSON into AionUi's `Settings → MCP →
Add Server → Import JSON` (or the equivalent for custom agents) on
   first launch of a new clone.

There is no magic auto-load. If a future addon under `flexnetos/addons/`
wants to hydrate `ProcessConfig` from these templates at boot, that's
fair game — it would be a FlexNetOS-owned tool, not a modification of
upstream code.

## Layout

```
.aionui-data/
├── .gitignore               deny-by-default policy (this directory only)
├── README.md                you are here
├── mcp-servers/             reference JSON for MCP server configurations
│   └── example.json
├── agents/                  reference JSON for custom ACP agents
│   └── example.json
└── AionUi-Dev/              (created by Electron at first launch — gitignored)
    ├── Local Storage/
    ├── IndexedDB/
    └── ...
```

## Why nested `.gitignore` instead of touching the root `.gitignore`

The root `.gitignore` is upstream-owned. Modifying it would violate the
zero-upstream-touch contract (`flexnetos/docs/CONTRACT.md`). Nested
`.gitignore` files are a native git feature with identical effect when
the patterns are kept inside the relevant subtree, so we get the same
behavior without divergence from upstream.
