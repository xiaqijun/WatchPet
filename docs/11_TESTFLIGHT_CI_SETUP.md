# TestFlight CI Setup Guide

This guide is for a no-Mac workflow. GitHub Actions or a cloud Mac can perform signing, archiving, and uploading, but the default repository only runs unsigned compile checks. TestFlight upload requires your own Apple Developer credentials.

## Apple information you need

| Item | Purpose |
|---|---|
| Apple Developer Program | Required paid developer account |
| Team ID | Found in Apple Developer membership settings |
| Bundle IDs | Must be unique; do not use `com.example.*` |
| App Store Connect app record | Required before upload |
| Distribution certificate | Apple Distribution signing certificate |
| Provisioning profile | App Store distribution profile |
| App Store Connect API key | Used by CI upload tooling |

## Suggested GitHub Secrets

| Secret | Purpose |
|---|---|
| `APPLE_TEAM_ID` | Apple Developer Team ID |
| `APPSTORE_API_KEY_ID` | App Store Connect API key ID |
| `APPSTORE_API_ISSUER_ID` | App Store Connect issuer ID |
| `APPSTORE_API_PRIVATE_KEY` | Full `.p8` private key content |
| `IOS_DIST_CERT_BASE64` | Base64 encoded `.p12` certificate |
| `IOS_DIST_CERT_PASSWORD` | Password for the `.p12` certificate |
| `IOS_PROVISION_PROFILE_BASE64` | Base64 encoded provisioning profile |

## Bundle ID replacement checklist

Replace these placeholders before signing:

- `com.example.WatchPet`
- `com.example.WatchPetCompanion`
- `com.example.WatchPet.Widget`

Example final IDs:

- `com.yourname.WatchPet`
- `com.yourname.WatchPetCompanion`
- `com.yourname.WatchPet.Widget`

## Current CI purpose

`.github/workflows/validate.yml` currently performs unsigned validation:

- Validate repository structure.
- Validate the sample `.watchpet` package.
- Build the watchOS app.
- Build the iPhone Companion app.
- Build the watchOS Widget.

This proves the code compiles, but it does not replace device signing or TestFlight upload.

## Manual readiness workflow

`.github/workflows/testflight-readiness.yml` can be run manually from GitHub Actions. It checks:

- whether required signing/upload secrets are present;
- whether Bundle ID and Team placeholders have been removed;
- whether the export options template exists;
- whether the normal repository validation still passes.

By default it is non-strict and creates a report. If you run it with `strict=true`, missing credentials or placeholders make the job fail.

## Local readiness check

After you create Apple identifiers and update the Xcode projects, run:

```bash
python scripts/check_testflight_readiness.py
```

A fresh clone is expected to print `NOT READY` because it still uses `com.example.*` placeholders and an empty Team ID.

## Recommended production project layout

For Windows/no-Mac development, this repository currently uses three separate Xcode projects. Before production TestFlight delivery, organize the project on a Mac as:

```text
WatchPetApp.xcodeproj or WatchPet.xcworkspace
+-- iOS Companion App target
+-- watchOS App target
+-- watchOS Widget Extension target
```

This makes App Store/TestFlight signing, versioning, App Groups, shared resources, and companion app relationships easier to manage.

## Manual archive example

Run these commands on a Mac after configuring Team, Bundle IDs, certificate, and provisioning profile:

```bash
xcodebuild archive   -project WatchPetCompanion.xcodeproj   -scheme WatchPetCompanion   -configuration Release   -archivePath build/WatchPetCompanion.xcarchive

xcodebuild -exportArchive   -archivePath build/WatchPetCompanion.xcarchive   -exportPath build/export   -exportOptionsPlist config/ExportOptions-AppStore.example.plist
```

Upload to TestFlight with Xcode Organizer, Transporter, or Apple's current command-line upload tool for your Xcode version.
