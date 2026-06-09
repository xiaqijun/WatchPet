# WatchPet

WatchPet is an Apple Watch virtual pet project. It turns a pet photo or a `.watchpet` asset package into a lightweight 2D animated pet that can live on Apple Watch.

The repository now includes a watchOS app, an iPhone Companion app, `.watchpet` package tooling, iPhone-to-Watch resource transfer, a Widget/Complication target, and no-Mac/TestFlight preparation docs.

## Current features

- Apple Watch app: pet animation, meters, pet/feed/sleep interactions, local state persistence.
- HealthKit step-count experience skeleton.
- iPhone Companion app: preview pet package animations, import packages, send the selected pet to Apple Watch.
- WatchConnectivity: sync pet metadata and transfer `manifest.json` plus PNG animation resources.
- `.watchpet` tooling: validate, pack, unpack, scaffold.
- Direct `.watchpet` zip import on iPhone: supports `.watchpet`, `.zip`, and unpacked folders.
- Local generation MVP: create an 8-action `.watchpet` package from one image without an API key.
- Watch Widget / Complication: standalone WidgetKit extension project.
- GitHub Actions: validates Python tools and builds watchOS, iOS Companion, and watchOS Widget projects on macOS runners.

## Project structure

```text
WatchPet/
+-- WatchPet.xcodeproj              # Apple Watch app Xcode project
+-- WatchPetCompanion.xcodeproj     # iPhone Companion Xcode project
+-- WatchPetWidget.xcodeproj        # watchOS Widget/Complication Xcode project
+-- WatchPet/                       # watchOS app source and assets
+-- WatchPetCompanion/              # iPhone Companion source and bundled sample package
+-- WatchPetWidget/                 # WidgetKit extension source and assets
+-- docs/                           # product, technical, no-Mac, and TestFlight docs
+-- scripts/                        # package tools, generator, repository validation
+-- examples/                       # sample .watchpet package and unpacked package
```

## Local tool usage

Validate the repository and sample package:

```bash
python scripts/validate_project.py
python scripts/watchpet_tool.py validate examples/mochi.watchpet
```

Pack or unpack `.watchpet` packages:

```bash
python scripts/watchpet_tool.py pack examples/mochi outputs/mochi.watchpet --force
python scripts/watchpet_tool.py unpack examples/mochi.watchpet work/mochi --force
```

Generate a local MVP pet package from one image:

```bash
python scripts/generate_watchpet_local.py pet.png outputs/my-pet.watchpet --name MyPet --keep-unpacked work/my-pet
python scripts/watchpet_tool.py validate outputs/my-pet.watchpet
```

`generate_watchpet_local.py` is an offline MVP. It does not require an API key. A future AI image provider can replace `render_frame()` while keeping the same package contract.

## No-Mac development path

- Daily Swift/Python/package work can continue on Windows.
- GitHub Actions uses macOS runners to prove the Xcode projects compile.
- Installing on a real iWatch requires Apple signing: borrowed/rented Mac direct install, or Apple Developer Program + TestFlight.
- See `docs/10_IWATCH_TESTING_GUIDE.md` and `docs/11_TESTFLIGHT_CI_SETUP.md`.

## Xcode projects

The current no-Mac-friendly setup uses three independently buildable Xcode projects:

1. `WatchPet.xcodeproj`: watchOS app.
2. `WatchPetCompanion.xcodeproj`: iPhone Companion app.
3. `WatchPetWidget.xcodeproj`: watchOS Widget/Complication.

Before a real TestFlight/App Store build, replace every `com.example.*` Bundle Identifier with your own unique IDs and set your Apple Developer Team.

## Documentation

- `docs/00_MASTER_PLAN.md`: master plan.
- `docs/01_PRD.md`: product requirements.
- `docs/02_WATCHPET_PACKAGE_SPEC.md`: `.watchpet` package spec.
- `docs/03_AI_GENERATION_PLAN.md`: AI generation plan and local MVP note.
- `docs/04_DEVELOPMENT_PLAN.md`: development milestones.
- `docs/05_DELIVERY_CHECKLIST.md`: delivery checklist.
- `docs/06_NO_MAC_DEVELOPMENT_GUIDE.md`: no-Mac workflow.
- `docs/07_WATCHPET_TOOL_GUIDE.md`: package tool guide.
- `docs/08_IPHONE_COMPANION.md`: iPhone Companion notes.
- `docs/09_WATCHCONNECTIVITY_SYNC.md`: sync notes.
- `docs/10_IWATCH_TESTING_GUIDE.md`: real Apple Watch / TestFlight guide.
- `docs/11_TESTFLIGHT_CI_SETUP.md`: TestFlight CI readiness guide.

## Current limitations

- This environment is Windows, so it cannot install to a real Apple Watch.
- Real iWatch validation still needs your Apple ID, Apple Developer Program, or a usable Mac.
- App icons are still placeholders.
- The three Xcode projects are split for easier no-Mac CI. Before production TestFlight delivery, it is recommended to organize them into a single workspace or a standard host iOS app project.

## License

MIT
