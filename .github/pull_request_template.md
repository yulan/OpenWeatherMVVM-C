## What and why

<!-- One or two sentences. Link the issue or ADR if there is one. -->

## How it was tested

<!-- Which lanes/tests you ran, and anything checked by hand (device, locale, dark mode, VoiceOver). -->

- [ ] `bundle exec fastlane ci` is green locally
- [ ] New behaviour has tests; bug fixes have a regression test

## Screenshots

<!-- UI changes: light and dark. Delete this section otherwise. -->

## Review checklist

- [ ] Layer rules respected (see CONTRIBUTING.md)
- [ ] Edge cases: offline, permission denied, empty, cancellation, single item
- [ ] Wording in `L10n` (en + fr), units and dates follow the locale
- [ ] No timing-dependent tests, no new `@unchecked Sendable` without a comment
- [ ] ADR added or updated if this changes an architectural decision
