# SAFE GIT WORKFLOW

This is the workflow we should follow for this project whenever Git is active.

Important note:

- the current folder is **not** a Git repository yet, so Git commands cannot run here until the repo is initialized or cloned properly

## Default Rules

- never commit directly to `main`
- never push unchecked changes
- never use `git add .` blindly unless we have already reviewed every changed file
- always inspect `git status` before staging
- always inspect `git diff --staged` before committing
- prefer small, task-based commits
- never commit secrets, `.env`, local caches, or machine-specific junk

## Safe Daily Flow

### 1. Start from the base branch

If the repo uses `main`:

```bash
git checkout main
git pull --ff-only origin main
```

If the repo uses `dev`:

```bash
git checkout dev
git pull --ff-only origin dev
```

### 2. Create or switch to a working branch

Examples:

```bash
git checkout -b feature/tech-spec
git checkout -b feature/round1-engine
git checkout -b fix/judge-score-floor
```

### 3. Review local changes before staging

Always check:

```bash
git status
git diff
```

Stage only the intended files:

```bash
git add docs/TECH_SPEC.md
git add app/admin/page.tsx
git add lib/game-engine.ts
```

Avoid broad staging unless we have verified everything.

### 4. Verify staged content

Before every commit:

```bash
git diff --staged
```

This is the last safety check against accidental files or mixed changes.

### 5. Commit with a scoped message

Examples:

```bash
git commit -m "docs: add project tech spec"
git commit -m "feat(round1): implement token bet validation"
git commit -m "fix(judges): floor average score correctly"
```

### 6. Push only the working branch

```bash
git push -u origin feature/tech-spec
```

### 7. Merge safely

Preferred:

- open a PR into `dev` or `main`
- review changes
- merge only after verification

If direct Git merge is explicitly desired:

```bash
git checkout main
git pull --ff-only origin main
git merge --ff-only feature/tech-spec
git push origin main
```

Use `--ff-only` whenever possible to avoid blind merges.

## Rebase / Sync Rule

If the base branch moved while we were working:

```bash
git fetch origin
git rebase origin/main
```

Or:

```bash
git fetch origin
git rebase origin/dev
```

If the branch was already pushed before rebasing:

```bash
git push --force-with-lease origin <branch-name>
```

Never force-push `main`.

## What I Should Do Before Any Commit In This Project

Whenever you ask me to `add`, `commit`, or `push`, I should follow this checklist:

1. Check whether this folder is actually a Git repo.
2. Check current branch with `git status` and `git branch --show-current`.
3. Review changed files before staging.
4. Stage only targeted files.
5. Review staged diff.
6. Commit with a clear scoped message.
7. Push only the feature branch unless you explicitly ask for another flow.

## Commit Message Style

Recommended pattern:

```text
type(scope): summary
```

Examples:

- `docs(spec): add gameplay tech spec`
- `feat(admin): add round1 verification grid`
- `feat(student): lock submission after timeout`
- `fix(score): floor judge average correctly`
- `refactor(state): simplify game phase enum`

## Unsafe Actions To Avoid

- `git add .` without review
- committing unrelated files together
- pushing directly to `main`
- `git push --force` on shared branches
- `git reset --hard` unless explicitly approved
- reverting user changes that were not part of the task

## Session Agreement

For the rest of this collaboration, when Git operations are needed, I will follow this workflow by default.
