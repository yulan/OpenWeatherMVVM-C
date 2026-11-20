@AGENTS.md

## Claude Code specifics

- The project rules live in AGENTS.md (imported above) so every agent reads the same file.
- For reviews, delegate to the `ios-reviewer` subagent defined in `.claude/agents/`.
- Prefer `bundle exec fastlane package_tests` for a fast feedback loop while editing the package; run the full `test` lane before handing work back.
