# FlexNetOS/AionUi-auto — fork workflow

This fork tracks `iOfficeAI/AionUi` upstream while letting us land our own features on a long-lived `develop` branch.

## Branch model

| Branch | Purpose | Who writes to it |
|---|---|---|
| `main` | **Pristine mirror** of `iOfficeAI/AionUi:main`. Byte-identical at all times. | Only the `sync-upstream` workflow (force-with-lease). |
| `develop` | **Default branch.** Our integration branch. Upstream changes arrive here via the `promote-main-to-develop` workflow. | Humans, via PR. |
| `feature/<slug>` | Per-feature work. | Branched off `develop`, PR'd back into `develop`. |

**Never push to `main` directly. Never branch off `main` for features.** Always branch off `develop`.

## How upstream changes flow

```
iOfficeAI/AionUi:main
       │
       │  sync-upstream.yml  (every 6h + manual; force-mirror)
       ▼
origin/main  (pristine, byte-identical to upstream)
       │
       │  promote-main-to-develop.yml  (chained on sync; FF or PR)
       ▼
origin/develop
       │
       │  PR from feature/<slug>
       ▼
your feature branches
```

## Daily commands

### Start a feature

```bash
git checkout develop
git pull
git checkout -b feature/<short-slug>
# … hack hack hack …
gh pr create --base develop --title 'feat: <thing>' --body '...'
```

### Pull upstream right now (don't wait for the schedule)

```bash
gh workflow run sync-upstream.yml --ref develop
gh run watch
```

The `promote-main-to-develop` workflow auto-fires on completion and either fast-forwards `develop` or opens `chore: sync upstream into develop` for you to merge.

### Keep your feature branch fresh

```bash
git checkout feature/<slug>
git fetch origin
git rebase origin/develop      # preferred — keeps history flat
# or
git merge origin/develop       # if rebasing is too disruptive
```

### Check sync status

```bash
gh api repos/FlexNetOS/AionUi-auto/compare/iOfficeAI:main...main --jq '.status'
# expect: "identical"
```

```bash
gh run list --workflow=sync-upstream.yml --limit 5
gh run list --workflow=promote-main-to-develop.yml --limit 5
```

## Safety rails

- `develop` is protected: no force-push, no deletion, all changes via PR.
- `main` accepts force-push **only** from the sync workflow (which uses `--force-with-lease`). If a human pushes to `main`, the next sync run fails loudly and files an issue with label `sync-failure`.
- Pre-commit gate (`prek run --from-ref origin/develop --to-ref HEAD`) is inherited from upstream.

## What's ours vs. upstream's

These files were added by FlexNetOS and don't exist upstream:

- `.github/workflows/sync-upstream.yml`
- `.github/workflows/promote-main-to-develop.yml`
- `docs/FORK_WORKFLOW.md` (this file)

Everything else mirrors `iOfficeAI/AionUi`. When upstream changes a file we've also modified (which currently only happens for our three files above — none of which upstream touches), the `promote-main-to-develop` workflow will surface the conflict in the sync PR.

## Emergency: undo a bad sync

If `sync-upstream` force-pushed something broken to `main`:

```bash
# Find the previous good SHA from the workflow run logs
gh run list --workflow=sync-upstream.yml --limit 5
gh run view <run-id> --log | grep 'Will mirror'

# Reset (requires repo admin)
git push origin <good-sha>:main --force-with-lease
```

But normally you don't need this — `main` always traces back to `upstream/main`, which never disappears.
