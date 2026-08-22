# apps/ipad — iPad Check-In App

Front-of-house app used on iPads at check-in: captures a guest's face, sends it to
`services/facial-recognition` for matching, and shows the verification result.

**Stack: TBD.** Candidates:

- Native SwiftUI — best camera access, offline-friendly, iPad-only.
- Web app (PWA) — reuses components/patterns from `apps/web`, fastest to build, runs in
  Safari/kiosk mode.
- React Native / Expo — cross-platform if Android is ever needed, still native camera access.

Not yet scaffolded — pick a stack before starting this app.
