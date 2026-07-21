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

## 3. GitHub Automation & Templates
- All workflow files use Node.js 24 (`actions/setup-node@v4` with `node-version: '24'`).
- Issue templates are configured in `.github/ISSUE_TEMPLATE/` (`bug_report.yml`, `feature_request.yml`).
- PRs must follow `.github/pull_request_template.md`.
- Code owners are defined in `.github/CODEOWNERS`.

## 4. Hardware Memory Cap (16GB RAM)
- When invoking local LLMs (via Ollama or local APIs), restrict model parameters to 7B or 8B (e.g. `qwen2.5-coder:7b` or `llama3.1:8b`). Do not attempt to run 32B/70B models locally.

## 5. File Directory & Path Stability (CodeRabbit Enforcement)
- **DO NOT modify, move, or rename existing file directories or path structures without explicit user approval.**
- CodeRabbit and custom pre-merge checks monitor path patterns (`juicer/sources/views/**`, `juicer/sources/models/**`, `project.yml`).
- Arbitrary file directory changes or renaming existing folders will break CodeRabbit path rules and trigger automated pre-merge check rejections.
