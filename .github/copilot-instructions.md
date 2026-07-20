# Juicer Repository Guidelines for AI Agents

These rules apply to all AI coding agents (GitHub Copilot Agent, Claude Code, Antigravity, OpenCode, Hermes, CrewAI):

## 1. Commit & Naming Conventions
- **Commit Messages**: Always format commit messages in lowercase as `xxx: xxx xxx xxx` (e.g. `fix: update menu bar monitor layout`).
- **Files & Folders**: All newly created files and directories MUST use lowercase names (e.g. `my_clean_crew`, `opencode.json`).

## 2. Build & Xcode Management
- This project uses **XcodeGen** to define `juicer.xcodeproj` from `project.yml`.
- Whenever you add, delete, or move Swift files or resources, run:
  ```bash
  xcodegen generate
  ```

## 3. Core Task Priorities
- Exercise features end to end.
- Reproduce UI hangs and memory leak issues.
- Fix any issues that require force-quitting the app.

## 4. Hardware Memory Cap (16GB RAM)
- When invoking local LLMs (via Ollama or local APIs), restrict model parameters to 7B or 8B (e.g. `qwen2.5-coder:7b` or `llama3.1:8b`). Do not attempt to run 32B/70B models locally.
