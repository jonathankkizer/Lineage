# dbtdagviewer

A native macOS app for exploring a dbt project as a graph. AppKit, Swift 6, no Electron, no browser tab.

See [`docs/design.md`](docs/design.md) for the pitch, scope, architecture, and roadmap.

## Layout

- `dbtdagviewer/` — Swift sources (auto-included by Xcode's `PBXFileSystemSynchronizedRootGroup`).
- `dbtdagviewer.xcodeproj/` — Xcode project.
- `docs/` — design docs.
- `fixtures/data-warehouse/target/` — a real dbt run's `target/` directory, used as the dev fixture. Open this folder from the app to see ~1,593 nodes.

## Building

Open `dbtdagviewer.xcodeproj` in Xcode 16+ and Cmd+R. Requires macOS 26+.
