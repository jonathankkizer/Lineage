# Lineage

A native macOS app for exploring a dbt project as a graph. AppKit, Swift 6, no Electron, no browser tab.

See [`docs/design.md`](docs/design.md) for the pitch, scope, architecture, and roadmap.

## Layout

- `Lineage/` — Swift sources (auto-included by Xcode's `PBXFileSystemSynchronizedRootGroup`).
- `Lineage.xcodeproj/` — Xcode project.
- `docs/` — design docs.
- `fixtures/` — gitignored. Drop a real dbt project's `target/` directory here (or anywhere on disk) and open it from the app for development.

## Building

Open `Lineage.xcodeproj` in Xcode 16+ and Cmd+R. Requires macOS 26+.
