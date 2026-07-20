# repository layout

Juicer uses a small public root and separates product documentation from implementation.

## public and tracked

```text
juicer/
  sources/
    models/
    views/
    resources/
project.yml
readme.md
license
security.md
contributing.md
code_of_conduct.md
docs/
  feature-opportunities.md
  open-source-feature-audit.md
  ui-improvements.md
```

The public surface should contain source code, reproducible project generation, product documentation, legal policy, security guidance, and screenshots that are intentionally part of the project presentation.

## local-only

```text
build/
juicer.xcodeproj/
DerivedData/
*.xcuserstate
*.zip
.claude/
codex.md
opencode.json
my_clean_crew/
galleries/
```

These are generated outputs, machine-specific settings, local agent instructions, unrelated workspace material, or distribution artifacts. They should not be used as the source of truth or committed accidentally.

## organization rules

- Keep Swift files grouped by role under `juicer/sources/models`, `juicer/sources/views`, and `juicer/sources/resources`.
- Keep roadmap, audits, and UI planning under `docs/`.
- Keep root files limited to project entry points, legal policy, and contributor-facing documentation.
- Generate `juicer.xcodeproj` from `project.yml` instead of committing the generated project.
- Store release archives in GitHub Releases or a package registry, not in Git history.
- Use lowercase names for every new file and folder.
