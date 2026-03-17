---
name: repo-context
description: Scans all repos in ~/Developer/work/ and ~/Developer/personal/, then creates or updates a context file per repo at ~/.claude/repo-context/<repo-name>.md. Use when the user runs /repo-context.
argument-hint: [optional: repo name or path to refresh a single repo]
---

# Repo Context Workflow

The user has invoked `/repo-context`. Your job is to scan all Git repositories across the two developer directories (or specific repo if provided as argument) and produce or refresh a context file for each one.

Context files live at: `~/.claude/repo-context/<repo-name>.md`

---

## Step 1 — Discover repos

Run these two commands to collect all repos:

```bash
ls ~/Developer/work/ 2>/dev/null
ls ~/Developer/personal/ 2>/dev/null
```

Build a flat list of entries in the form `<source>/<repo-name>` where source is `work` or `personal`, e.g.:

```
work/api-service
work/mobile-app
personal/side-project
```

If the user supplied an argument, filter the list to only repos whose name matches.

Ensure `~/.claude/repo-context/` exists:

```bash
mkdir -p ~/.claude/repo-context
```

---

## Step 2 — Filter and process repos

**Check which repos already have context files:**

```bash
ls ~/.claude/repo-context/ 2>/dev/null
```

- If the user supplied an argument: always process the matching repo (refresh it), regardless of whether a context file exists.
- If no argument was supplied: **skip** any repo whose context file already exists (`~/.claude/repo-context/<repo-name>.md`). Only queue repos with no existing file.

Tell the user upfront: how many repos were found, how many already have context (skipped), and how many will be processed now.

If all repos already have context and no argument was given, refresh all context files.

Split the remaining repo list into chunks of up to **10 repos**. For each chunk, launch all subagents **in parallel** (in a single message with multiple Agent tool calls, all with `run_in_background: true`).

Wait for each batch to complete before starting the next batch.

For each repo, spawn a `general-purpose` subagent with the prompt template below. Substitute the actual values for `REPO_NAME`, `REPO_PATH`, and `CONTEXT_FILE`.

---

## Subagent prompt template

```
You are building a context file for a single Git repository so that Claude can quickly understand it in future sessions.

## Your assignment

Repo name:    <REPO_NAME>
Repo path:    <REPO_PATH>
Context file: <CONTEXT_FILE>

## Phase 1 — Load existing context (if any)

Check whether the context file already exists:

  cat "<CONTEXT_FILE>" 2>/dev/null

If it exists, read it carefully. You will update it — keeping what is still accurate, correcting what is wrong or outdated, and filling in anything missing.

## Phase 2 — Understand the repo

Work through the following, spending more time where there is more signal:

1. **Identity** — Read README.md (or README, README.rst, docs/README.md). If absent, check the repo root for any `.md` files.
2. **Language & build system** — Detect from: package.json, go.mod, go.sum, Podfile, Podfile.lock, build.gradle, pom.xml, Cargo.toml, pyproject.toml, setup.py, requirements.txt, Makefile, .xcode*, *.xcworkspace, *.xcodeproj.
3. **Entry points** — Find main files, server start-up, CLI entry points, app delegates, etc.
4. **Architecture** — Read 10–20 key source files to understand the major layers, modules, or services inside the repo. Focus on structure, not line-by-line detail.
5. **Dependencies on other internal repos** — Search for references to sibling repo names found in ~/Developer/work/ and ~/Developer/personal/ inside: package.json (dependencies/devDependencies), go.mod (replace directives or module imports), Podfile (local path pods), import statements, or any workspace/monorepo config.
6. **External service communication** — Grep for patterns that reveal how this service talks to the outside world:
   - REST: `http.Get`, `fetch(`, `axios`, `URLSession`, `Alamofire`, `httpClient`, `baseURL`, `.get(`, `.post(`
   - gRPC: `.proto` files, `grpc`, `protobuf`, `connectrpc`
   - GraphQL: `gql`, `graphql`, `Apollo`
   - WebSocket: `websocket`, `ws://`, `wss://`
   - Message queues: `kafka`, `rabbitmq`, `nats`, `pubsub`, `SQS`, `SNS`
   - Databases: connection strings, ORM configs, migration files
   For each hit, record what it communicates with (endpoint, topic, service name) if discernible.
7. **Design patterns** — Identify architectural and code-level patterns in use. For each area of the codebase (e.g. data layer, networking, UI, domain logic), note which pattern is used. If multiple conflicting patterns exist (e.g. both callbacks and async/await for networking, or both MVVM and MVC for UI), determine which is newer by checking git log dates (`git log --diff-filter=A --follow --format="%ad %f" -- <file>`) on representative files from each pattern, or by reading CHANGELOG/PR descriptions if available. Record the verdict: which pattern is canonical for new code.
8. **Environment / config** — Scan `.env.example`, `config/`, `*.yml`, `*.yaml`, `*.toml` for service names, base URLs, and feature flags that reveal integrations.
9. **CI/CD & deployment** — Glance at `.github/workflows/`, `Dockerfile`, `docker-compose.yml`, `k8s/`, `*.tf` to understand how the service is built and deployed.

## Phase 3 — Write the context file

Write (or overwrite) `<CONTEXT_FILE>` with the following structure. Be concise but complete — this file is read by Claude, not humans, so prefer dense, accurate prose over padding.

---

```md
# <REPO_NAME>

## Purpose
One or two sentences describing what this repo does and who/what uses it.

## Responsibility
What problem does this repo own? What are its boundaries (what does it NOT do)?

## Language & stack
Primary language, framework(s), build tool.

## Architecture
Brief description of the internal structure: layers, major packages/modules, key patterns (MVC, clean arch, event-driven, etc.).

## Entry points
How is the repo started, invoked, or consumed? (CLI command, server binary, library import, mobile app target, etc.)

## Internal repo dependencies
List sibling repos from ~/Developer/work/ or ~/Developer/personal/ that this repo depends on, with a one-line reason each.
- none (if none found)

## Repos that likely depend on this one
List sibling repos that appear to import or call this repo (if you can infer it from naming or config).
- none (if none found)

## External communication
Describe how this service communicates with the outside world. For each protocol/integration:
- **REST** → [endpoint base URLs or service names]
- **gRPC** → [proto service names or endpoints]
- **GraphQL** → [schema or client details]
- **WebSocket** → [what streams]
- **Message queue** → [topic/queue names, broker]
- **Database** → [type, ORM, migration tool]
Omit sections that do not apply.

## Design patterns
For each major area of the codebase, state the pattern(s) in use. If there are conflicts (old and new approaches coexisting), name both and state which is canonical for new code — with a brief reason (e.g. "async/await supersedes callbacks, introduced in v2 migrations starting 2024").

Format:
- **<Area>**: <pattern(s)>. [If conflict: use <canonical pattern> for new code — <reason>.]

Example areas: UI, networking, data persistence, domain/business logic, dependency injection, error handling, concurrency.

## Environment & config
Key environment variables or config values that affect behaviour (from .env.example, config files, etc.).

## Deployment
How is this built and deployed? (Docker, k8s, GitHub Actions, Xcode, etc.)

## Notes for Claude
Any quirks, conventions, or gotchas that are useful to know when working in this repo.

## Last updated
<today's date in YYYY-MM-DD>
```

---

## Rules

- Do not truncate any section — if you cannot determine the answer write "Unknown".
- If updating an existing file: preserve sections that are still accurate, correct outdated info, and add missing sections.
- Do not include raw file dumps or long code snippets in the context file — summarise instead.
- Today's date for "Last updated" is <TODAY>.
```

---

## Step 3 — Report

After all batches complete, report to the user:
- How many repos were processed
- How many context files were created vs updated
- The path `~/.claude/repo-context/`
- Any repos that failed or could not be read (e.g. empty repos, permission errors)
