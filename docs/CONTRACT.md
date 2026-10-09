# Shared contract (all agents must follow)

- Bundle ID: `fi.anatti.app`. Display name: `Anatti`. iOS/iPadOS 26.0+ deployment target, built with Xcode 27 / Swift 6.
- Languages (String Catalog locales): `en` (source), `es`, `de`, `fi`, `sv`, `fr`, `it`.
- Subscription: group `anatti_pro`, product ID `fi.anatti.pro.monthly`, auto-renewable, 1 month, 7.99 EUR.
- All user data stays on device (SwiftData + Application Support). No servers, analytics, accounts or CloudKit. Privacy label: "Data Not Collected".
- Files: each agent edits ONLY its own paths (docs/AGENTS.md). Do not git commit; the lead commits.
- Swift cannot be compiled in this Linux sandbox. Write careful, idiomatic Swift 6 (strict concurrency, `@MainActor` UI, `Sendable` models) and re-read your code for compile errors.

## Localization keys (String Catalog `App/Resources/Localizable.xcstrings`)
Use these exact keys in code via `String(localized:)` / `Text("key")`.

| Key | English source |
|---|---|
| app.name | Anatti |
| tab.projects | Projects |
| tab.export | Export |
| tab.settings | Settings |
| projects.empty.title | No projects yet |
| projects.empty.message | Create a project to generate store screenshots and videos. |
| projects.new | New Project |
| settings.pro | Anatti Pro |
| settings.restore | Restore Purchases |
| settings.manage | Manage Subscription |
| settings.privacy.note | Everything stays on this device. |
| paywall.title | Unlock Anatti Pro |
| paywall.subtitle | Create App Store and Google Play screenshots and videos in minutes. |
| paywall.feature.sizes | Every required size for App Store and Google Play |
| paywall.feature.video | App preview videos that meet store rules |
| paywall.feature.local | 100% on-device. Your files never leave your phone. |
| paywall.feature.languages | Localized in 7 languages |
| paywall.cta | Subscribe for %@ per month |
| paywall.price.fallback | 7.99 € per month |
| paywall.renewal | Renews monthly until cancelled. Cancel anytime in Settings. |
| paywall.restore | Restore Purchases |
| paywall.terms | Terms of Use |
| paywall.privacy | Privacy Policy |
| paywall.close | Close |
| paywall.error.generic | Something went wrong. Please try again. |
| paywall.error.unavailable | Subscription is not available right now. |
| paywall.pending | Your purchase is waiting for approval. |
| paywall.thanks | Thank you! Anatti Pro is active. |
| export.locked | Export requires Anatti Pro |
| export.unlock | Unlock Pro |
