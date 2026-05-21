# flexnetos/addons/

Reserved namespace for FlexNetOS-owned extensions that need real source code
(TypeScript / JavaScript / shell). Anything that is data-only (MCP server
configs, agent definitions, prompts) lives under `.aionui-data/` instead —
the upstream app picks those up automatically on first launch.

## When to put code here

- A wrapper that pre-processes config before launching AionUi.
- A standalone CLI that operates on `.aionui-data/`.
- A node module imported by `flexnetos/launch/run-in-place.sh` via `bun x`.

## When NOT to put code here

- If a feature requires modifying `src/`, `tests/`, or any other upstream-owned
  path — that breaks the zero-upstream-touch contract (`flexnetos/docs/CONTRACT.md`).
  Open an upstream PR or use `patches/` via `patch-package` instead.
- If a feature is purely a configuration value — put the config under
  `.aionui-data/mcp-servers/` or `.aionui-data/agents/` so AionUi reads it
  natively.

## Layout convention

Each addon gets its own subdirectory with a `README.md` explaining what it
does and how to invoke it. Keep the top of `flexnetos/addons/` at ≤ 10 direct
children; split into themed subfolders if you approach the limit (matches
the repo-wide `directory size ≤ 10` rule from `AGENTS.md`).
