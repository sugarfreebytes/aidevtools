---
description: Look up the latest published versions of the AI coding assistants pinned in the Dockerfile and update the ARG lines in place.
allowed-tools: Read, Edit, Bash(npm view *), Bash(curl *), WebFetch, WebSearch
---

# Update AI tool versions in the Dockerfile

Your job is to refresh the pinned versions for the AI coding assistants in `Dockerfile` to whatever is current upstream right now, then edit the Dockerfile in place.

## Steps

1. **Read** `Dockerfile` and extract the current values for every `ARG *_VERSION` line whose tool is an AI assistant. Today that means:
   - `CLAUDE_VERSION` — Claude Code CLI, installed via `https://claude.ai/install.sh`
   - `CODEX_VERSION` — npm package `@openai/codex`
   - `GEMINI_VERSION` — npm package `@google/gemini-cli`

   If new `ARG *_VERSION` lines have been added for other AI assistants (e.g. opencode, cursor, copilot), include them too. Skip non-AI versions (Java, Node, Python, Go, Deno, NVM).

2. **Look up the latest version** of each tool. Prefer the authoritative source per tool:
   - npm packages → `npm view <package> version` (fast, no auth needed). Both `@openai/codex` and `@google/gemini-cli` are on npm.
   - Claude Code CLI → fetch `https://claude.ai/install.sh` and read the version it defaults to, or check the GitHub releases page for `anthropics/claude-code`. Pick whichever returns a clean version string.
   - For any other tool: use `npm view` if it's an npm package, otherwise WebFetch the project's releases page or WebSearch for "<tool> latest version".

   Run these lookups in parallel where possible.

3. **Compare** each fetched version to what's currently in the Dockerfile. Build a short table of `tool: current → latest` and print it so the user can see what's about to change.

4. **Edit the Dockerfile**: for each tool whose version actually changed, update the corresponding `ARG <TOOL>_VERSION=<value>` line. Use the Edit tool, one edit per line. Do not touch lines for tools that are already up to date. Do not reformat or reorder anything.

5. **Report** the final result: list each tool with `unchanged` or `old → new`. Do not commit — leave the diff staged for the user to review.

## Notes

- The Claude install script convention is `bash -s <version>` with a bare semver (no `v` prefix). Match the existing format in the Dockerfile for each tool (some have a `v` prefix, some don't — preserve whatever style is already there).
- If a lookup fails (network error, package renamed, etc.), report it and skip that tool rather than guessing a version.
- Do not invent new ARG lines or install new tools — this command only refreshes existing pins.
