# Agents and ownership

| Agent | Owns (edit only these) | Task |
|---|---|---|
| Skeleton | `project.yml`, `App/**` except `App/Resources/Localizable.xcstrings` and `App/Resources/InfoPlist.xcstrings`, `README.md` | XcodeGen project, app entry, SwiftData models, Liquid Glass navigation shell |
| Paywall | `Sources/AnattiPro/**`, `Tests/AnattiProTests/**`, `Configuration/**` | StoreKit 2 subscription manager, paywall UI, Pro gating, StoreKit test config |
| Localization | `App/Resources/Localizable.xcstrings`, `App/Resources/InfoPlist.xcstrings`, `docs/metadata/**` | 7-language String Catalog and Anatti's own App Store listing text |
| Reviewer (after the others) | read-only; reports issues | Cross-check compile errors, contract, StoreKit/privacy rules |
