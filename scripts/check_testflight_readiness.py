#!/usr/bin/env python3
"""Check whether the repository is ready for TestFlight signing/upload.

A fresh clone is expected to be NOT READY because it still uses com.example
Bundle IDs and an empty Apple Developer Team. Use --strict in CI when you want
missing credentials/placeholders to fail the job.
"""
from __future__ import annotations

import argparse
import os
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PROJECTS = [
    ROOT / "WatchPet.xcodeproj/project.pbxproj",
    ROOT / "WatchPetCompanion.xcodeproj/project.pbxproj",
    ROOT / "WatchPetWidget.xcodeproj/project.pbxproj",
]
PLACEHOLDERS = [
    "com.example.WatchPet",
    "com.example.WatchPetCompanion",
    "com.example.WatchPet.Widget",
    "DEVELOPMENT_TEAM = "";",
    "DEVELOPMENT_TEAM = ;",
]
REQUIRED_SECRETS = [
    "APPLE_TEAM_ID",
    "APPSTORE_API_KEY_ID",
    "APPSTORE_API_ISSUER_ID",
    "APPSTORE_API_PRIVATE_KEY",
    "IOS_DIST_CERT_BASE64",
    "IOS_DIST_CERT_PASSWORD",
    "IOS_PROVISION_PROFILE_BASE64",
]


def collect_problems(check_secrets: bool) -> list[str]:
    problems: list[str] = []
    for project in PROJECTS:
        if not project.exists():
            problems.append(f"Missing project: {project.relative_to(ROOT)}")
            continue
        text = project.read_text(encoding="utf-8-sig")
        for placeholder in PLACEHOLDERS:
            if placeholder in text:
                problems.append(f"{project.relative_to(ROOT)} still contains placeholder: {placeholder}")

    export_options = ROOT / "config/ExportOptions-AppStore.example.plist"
    if not export_options.exists():
        problems.append("Missing config/ExportOptions-AppStore.example.plist")

    if check_secrets:
        for secret in REQUIRED_SECRETS:
            if not os.environ.get(secret):
                problems.append(f"Missing environment secret: {secret}")

    return problems


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Check TestFlight signing readiness")
    parser.add_argument("--check-secrets", action="store_true", help="also require Apple signing/upload secrets in the environment")
    parser.add_argument("--strict", action="store_true", help="return exit code 1 when readiness problems are found")
    args = parser.parse_args(argv)

    problems = collect_problems(check_secrets=args.check_secrets)
    if problems:
        print("TestFlight readiness: NOT READY")
        for problem in problems:
            print(" -", problem)
        return 1 if args.strict else 0

    print("TestFlight readiness: READY")
    print("Next: archive on Mac/cloud Mac and upload to App Store Connect.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
