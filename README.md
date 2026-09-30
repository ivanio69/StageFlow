# StageFlow

StageFlow is a native iPhone + Apple Watch tool for production teams to run rehearsals against a planned timeline, record what actually happened, capture notes, and see whether the rehearsal is ahead of or behind schedule.

## MVP scope

- Productions / projects
- Rehearsals inside a production
- Timeline blocks with planned start/end
- Actual start/end and status tracking
- Live schedule drift (`ahead / behind`)
- Predicted rehearsal finish time
- Notes linked to rehearsal or a specific block
- Run mode designed for one-handed use in a dark auditorium
- Apple Watch companion showing the current block and schedule drift
- WatchConnectivity snapshot sync foundation

## Project structure

- `StageFlowApp/` — iOS SwiftUI app
- `StageFlowWatchApp/` — watchOS SwiftUI app
- `StageFlowShared/` — shared DTOs used by both targets
- `project.yml` — XcodeGen project definition

## Generate the Xcode project

Install XcodeGen if needed:

```bash
brew install xcodegen
```

Then:

```bash
xcodegen generate
open StageFlow.xcodeproj
```

The project targets iOS 18+ and watchOS 11+ and uses SwiftData for local persistence.

## First roadmap

1. Harden timeline editing and reordering.
2. Add Live Activity / Dynamic Island.
3. Add CloudKit sync.
4. Add shared production-team access and roles.
5. Add rehearsal analytics and reusable templates.
