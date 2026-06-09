# Apple Watch Device / TestFlight Testing Guide

You have an iWatch but no Mac. This repository can already compile on GitHub Actions macOS runners. Installing on a real Apple Watch still requires Apple's signing and distribution chain.

## What is ready now

- `WatchPet.xcodeproj`: watchOS app, compiled in CI.
- `WatchPetCompanion.xcodeproj`: iPhone Companion app, compiled in CI.
- `WatchPetWidget.xcodeproj`: watchOS Widget/Complication, compiled in CI.
- `.watchpet` import and iPhone-to-Watch resource transfer code.
- `scripts/watchpet_tool.py`: package validate/pack/unpack/scaffold tool.
- `scripts/generate_watchpet_local.py`: offline `.watchpet` generation MVP.

## Route A: borrowed or rented Mac, direct device install

This is the fastest way to test on your Apple Watch.

1. Install Xcode on the Mac.
2. Sign in to Xcode with your Apple ID.
3. Clone the repo: `git clone https://github.com/xiaqijun/WatchPet.git`.
4. Open the three projects:
   - `WatchPet.xcodeproj`
   - `WatchPetCompanion.xcodeproj`
   - `WatchPetWidget.xcodeproj`
5. Replace `com.example.*` Bundle IDs with your own unique IDs, for example:
   - `com.yourname.WatchPet`
   - `com.yourname.WatchPetCompanion`
   - `com.yourname.WatchPet.Widget`
6. Select your Apple Developer Team.
7. Make sure the iPhone and Apple Watch are paired and use the same Apple ID.
8. Run the iPhone Companion app on the iPhone.
9. Run WatchPet on the Apple Watch.
10. In the iPhone Companion app, import a `.watchpet` package and tap `Send current pet and resources`.

## Route B: TestFlight

Use this if you cannot use a Mac directly but can use a cloud Mac or CI signing flow.

Requirements:

- Apple Developer Program account.
- App record in App Store Connect.
- Unique Bundle IDs.
- Apple Distribution certificate and provisioning profile.

Flow:

1. Create App ID / Bundle ID entries in Apple Developer.
2. Create an Apple Distribution certificate.
3. Create App Store provisioning profiles.
4. Archive with Xcode, a cloud Mac, or CI.
5. Upload to App Store Connect.
6. Add your Apple ID as a TestFlight tester.
7. Install the TestFlight build on iPhone; then install the Watch app on Apple Watch.

See `docs/11_TESTFLIGHT_CI_SETUP.md` for CI preparation.

## Route C: continue without a Mac

- Continue editing Swift, package assets, and Python tools on Windows.
- Use GitHub Actions to validate Xcode builds.
- When you need real iWatch installation, rent a cloud Mac or borrow a Mac for signing.

## Real-device acceptance checklist

- Watch app launches and plays the bundled pet animation.
- Tap pet, Feed, and Sleep all update animation and meters.
- iPhone Companion imports a `.watchpet` zip file.
- iPhone sends metadata and PNG resources through WatchConnectivity.
- Watch loads the imported pet after receiving resources and after app restart.
- Widget/Complication can be added to supported watch face slots.
- After HealthKit authorization, step count can increase pet experience.

## Notes

- The current no-Mac setup splits watchOS, iOS Companion, and Widget into separate projects. Before production TestFlight delivery, organize them into a workspace or a standard host iOS app + Watch app + Widget structure on a Mac.
- If you only want to try the watch pet first, install `WatchPet.xcodeproj` on Apple Watch first; test iPhone Companion and Widget later.
- Resource sync requires both iPhone Companion and WatchPet to be installed. WatchConnectivity can use reachable messaging or background file transfer depending on device state.
