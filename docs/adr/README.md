# Architecture Decision Records

Each file records one significant decision: the context, what we chose, what we rejected and what it costs us. They are written for the next person who asks "why is it like this?", including future us.

| # | Decision | Status |
|---|---|---|
| [0001](0001-mvvm-c-with-stateful-coordinators.md) | MVVM-C with coordinators that own navigation state | Accepted |
| [0002](0002-layered-modularization-with-local-spm.md) | Layered modularization with a local Swift package | Accepted |
| [0003](0003-typed-domain-errors.md) | A closed `DomainError` vocabulary with typed throws | Accepted |
| [0004](0004-offline-weather-cache-as-decorator.md) | Offline weather cache as a repository decorator | Accepted |
| [0005](0005-own-image-pipeline.md) | An image pipeline instead of `AsyncImage` | Accepted |
| [0006](0006-canonical-metric-units.md) | Canonical metric units, converted in presentation | Accepted |
| [0007](0007-ci-with-fastlane-and-circleci.md) | CI with Fastlane lanes and CircleCI | Accepted |

## Writing a new ADR

1. Copy [template.md](template.md) to `NNNN-short-title.md` with the next number.
2. Keep it to one page. Alternatives and consequences matter more than the decision itself.
3. Open it in the same pull request as the code it explains.
4. Never rewrite an accepted ADR. If a decision changes, write a new one and mark the old one *Superseded by NNNN*.
