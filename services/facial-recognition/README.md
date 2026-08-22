# services/facial-recognition — Facial Recognition Service

Enrolls guest faces and matches a captured face at check-in against enrolled guests.

**Stack: TBD.** Likely a Python service given the CV/ML library ecosystem (e.g.
`face_recognition`, OpenCV, dlib, or a hosted vision API), but not committed yet.

**Before writing real code here:** decide how face data is captured, stored, and retained.
Facial recognition data is biometric data and several jurisdictions (e.g. Illinois' BIPA)
impose specific consent/storage/retention requirements — see
[docs/architecture.md](../../docs/architecture.md#data--privacy-notes-to-revisit-before-building-the-facial-recognition-service).

Not yet scaffolded.
