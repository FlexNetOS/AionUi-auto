# Run AionUi in place

The clone IS the install. All AionUi userData (MCP servers, custom agents,
conversation history, IndexedDB) lives inside `<repo>/.aionui-data/` instead
of `~/.config/AionUi*/`, so the whole runtime is version-controlled and
portable to any other machine just by re-cloning.

This works in **three modes**, all driven by the same wrapper script
`flexnetos/launch/run-in-place.sh`. Pick whichever suits the moment.

## Mode A — Dev mode (default)

```bash
flexnetos/launch/run-in-place.sh
```

Equivalent to `bun run start` with `XDG_CONFIG_HOME` redirected. Hot reload,
source maps, React DevTools all available. Best for hacking on FlexNetOS
features that touch `flexnetos/` or `.aionui-data/`.

Renderer artifacts are served by `electron-vite dev`; the main-process app
runs against the actual electron binary, so all real APIs (file system,
electron-store, IPC) are exercised exactly as in production.

## Mode B — Web UI (browser)

```bash
flexnetos/launch/run-in-place.sh --webui
```

Equivalent to `bun run webui`. Spawns the same Electron process but in
headless ozone mode, exposing an Express + WebSocket server you can reach
from a browser on the LAN. Useful from a tablet, another desktop, or remote
shell.

The web UI reads the same `<repo>/.aionui-data/` config as Mode A, so MCP
servers and agents you configure here apply everywhere.

## Mode C — Packaged build with config redirect

```bash
bun run build-deb                     # one-time: build dist/aionui_<ver>_amd64.deb
sudo dpkg -i dist/aionui_*_amd64.deb  # OR: just point at dist/linux-unpacked/aionui
flexnetos/launch/run-in-place.sh --mode dist:linux  # or wrap the dist binary
```

For a daily-driver install. The wrapper still exports `XDG_CONFIG_HOME`,
so the packaged binary continues to read and write inside the clone — no
separate config tree to keep in sync.

If you want the .desktop launcher to appear in the GNOME / KDE app menu:

```bash
flexnetos/launch/install-launcher.sh
```

To remove it later:

```bash
flexnetos/launch/uninstall-launcher.sh
```

## Where files actually land

After the first launch:

```
.aionui-data/
├── .gitignore                  ignores secrets, cache, IndexedDB, etc.
├── README.md
├── AionUi-Dev/                 (dev mode) — Electron's userData dir
│   ├── Local Storage/
│   ├── IndexedDB/
│   ├── GPUCache/
│   └── ...
├── AionUi/                     (packaged mode) — same layout, different appName
├── mcp-servers/                committed templates + your additions
└── agents/                     committed templates + your additions
```

The Electron-managed subdirectories (`AionUi-Dev/`, `AionUi/`) are entirely
gitignored — the repo doesn't track conversation history or session storage.
Only the human-authored config under `mcp-servers/` and `agents/` is tracked.

## Why `XDG_CONFIG_HOME`?

Electron resolves the userData path on Linux via `XDG_CONFIG_HOME / <app-name>`.
Setting that env var redirects the entire userData root in one shot, without
needing `--user-data-dir` to thread through `electron-vite dev`'s argv parser
and without touching `src/index.ts` or `src/process/utils/configureChromium.ts`.

See `flexnetos/docs/CONTRACT.md` for the full set of upstream-untouched
invariants this approach upholds.
