# Contributing to This Project

How we work in this repository: getting set up, making a change, and what's expected before it merges. The repo is already configured — this covers how to work inside it.

> Replace "This Project" with the repo name, and point the dependency and test commands below at what this project actually uses.

---

## Getting set up

1. Ask the maintainer for access to the repository.
2. Clone it:
   ```bash
   git clone https://github.com/the-org/the-repo.git
   cd the-repo
   ```
3. Install dependencies and confirm it runs locally — see the README for this project's commands.

---

## Ground rules

- **Work on a branch, never on `main`.** `main` is protected, so direct pushes are rejected; everything lands through a reviewed pull request.
- **Never commit secrets** — keys, tokens, `.env` files. They stay in the history once pushed. If one slips through, tell the maintainer straight away.
- **Keep changes small and focused.** One branch, one concern. Smaller PRs review faster and break less.

---

## The everyday workflow

1. Update `main`:
   ```bash
   git switch main
   git pull
   ```
2. Branch off it, named for the work:
   ```bash
   git switch -c feature/login-form
   ```
3. Commit as you go:
   ```bash
   git add .
   git commit -m "feat: add login form"
   ```
4. Push the branch:
   ```bash
   git push -u origin feature/login-form
   ```
5. Open a pull request from the **Compare & pull request** prompt. Describe what changed and why, and link any related issue.
6. Address review by pushing more commits to the same branch; the PR updates itself.
7. Once approved and CI is green, **Squash and merge**, then delete the branch.
8. Switch back to `main`, pull, and start the next task.

---

## Branch names

Prefix by type, then a short description:

- `feature/` — new functionality (`feature/export-to-csv`)
- `fix/` — a bug fix (`fix/login-crash`)
- `chore/`, `docs/`, `refactor/` — maintenance, docs, tidying

---

## Commit messages

We use Conventional Commits — a type, then a present-tense summary:

```text
feat: add user login form
fix: stop crash when email field is empty
docs: explain how to run the tests
```

Types: `feat`, `fix`, `docs`, `refactor`, `test`, `chore`. Keep the summary under ~70 characters. The changelog is generated from these, so the history needs to read cleanly.

---

## Run the checks before pushing

Every PR runs CI. Run the same checks locally first so you're not waiting on a red build:

```bash
ruff check .   # formatting and style
pytest         # tests
```

If the repo uses pre-commit, install it once and the checks run on every commit:

```bash
pip install pre-commit
pre-commit install
```

---

## What makes a good PR

- One logical change. If it's sprawling, split it.
- A description covering what changed and why, with the issue linked.
- CI green before you request review.
- The PR template completed, if there is one.

When CI fails, open **Details** on the failing check, read the log for the step that broke, fix it, and push again — CI re-runs on its own.

---

## Code review

As the author: respond to every comment — make the change, or say why not. As the reviewer: be specific, suggest rather than dictate, and mark non-blocking notes with `nit:`.

---

## After merge

Your branch is squashed into a single commit on `main`. Merging may trigger a deploy to staging, so a green, reviewed `main` is what keeps the downstream environments healthy.

---

## Reporting bugs

Open an issue: what you expected, what happened, and steps to reproduce. The maintainer triages and labels.

---

## Cheat sheet

```bash
git switch main && git pull              # latest main
git switch -c feature/my-task            # new branch
git add . && git commit -m "feat: ..."   # stage and commit
git push -u origin feature/my-task       # push the branch
# open a PR, get it reviewed, squash-merge
git switch main && git pull              # back to main

git status        # what's changed
git log --oneline # recent commits
git diff          # unstaged changes
```

---

## First-PR checklist

- [ ] Cloned and running locally
- [ ] On a branch, not `main`
- [ ] Commits follow `type: summary`
- [ ] Checks pass locally
- [ ] PR opened with a clear description and linked issue
- [ ] CI green, review requested
- [ ] No secrets committed
