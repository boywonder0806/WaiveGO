# apps/ipad — iPad Check-In App

Front-of-house app used on iPads at check-in: captures a guest's face, sends it to
`services/facial-recognition` for matching, and shows the verification result.

**Stack: Native SwiftUI** (`WaiveGO/WaiveGO.xcodeproj`) — best camera access, works offline if
the network drops mid-shift, iPad-only kiosk build.

## Current state

Skeleton check-in flow only — `idle → scanning → verified/not-verified` — driven by mock data
in `CheckInViewModel` (see `#if DEBUG` buttons on the check-in screen to jump straight to each
result state). No camera capture, no facial-recognition service, and no API calls yet.

```
WaiveGO/WaiveGO/
  WaiveGOApp.swift          App entry point
  Models/CheckInStatus.swift    Check-in state + result types
  ViewModels/CheckInViewModel.swift  State machine (currently mocked)
  Views/CheckInView.swift       Kiosk screen (idle/scanning/result)
```

## Open next steps

- Wire real camera capture (AVFoundation/Vision) into `CheckInViewModel.startScan()`.
- Call `services/facial-recognition` (and, through it, the Smartwaiver-backed
  `services/api`) instead of the current 1.5s mock delay.
- Decide the guest-not-found flow: send them to sign a waiver on the spot, or flag staff?
- App icon / branding, and kiosk lock-down (Guided Access or MDM) for production iPads.

## Opening the project

Open `WaiveGO/WaiveGO.xcodeproj` in Xcode and run on an iPad simulator or device. Uses Xcode's
file-system-synchronized groups, so new files added under `WaiveGO/WaiveGO/` are picked up
automatically — no project file editing needed.
