# Anatti

Anatti is an iPhone and iPad app that generates App Store and Google Play listing material: screenshots, preview videos, Play icon and feature graphic, and Product Page Optimization images. Everything runs on device (SwiftData and Application Support). There are no servers, accounts, analytics or CloudKit. Export is unlocked by the Anatti Pro subscription (`fi.anatti.pro.monthly`, 7.99 EUR per month).

See `docs/` for the plan (`DESIGN.md`), store size specs (`SPECS.md`) and the shared contract (`CONTRACT.md`).

## Layout
- `Sources/AnattiCore`: SwiftPM, store spec catalog (pure Swift, testable on any platform).
- `Sources/AnattiPro`: SwiftPM, StoreKit 2 subscription manager and paywall.
- `App/`: the iOS app target (SwiftUI, Liquid Glass, SwiftData models).
- `project.yml`: XcodeGen definition. The `.xcodeproj` is generated and not committed.

## Build
1. `brew install xcodegen`
2. `xcodegen` in the repo root generates `Anatti.xcodeproj`.
3. Open `Anatti.xcodeproj` in Xcode 27 (iOS 26.0+ deployment target, Swift 6).
4. Run the `Anatti` scheme. It uses `Configuration/Anatti.storekit` as its StoreKit configuration, so the subscription can be tested in the simulator.

## Tests
- `swift test` runs the AnattiCore (and AnattiPro) package tests.
- App tests (`AnattiTests`) run from Xcode with the `Anatti` scheme.
