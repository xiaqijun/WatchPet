#!/usr/bin/env python3
"""Check whether the repository has been customized for TestFlight signing.

This script is intentionally not part of the default CI because a fresh clone
still uses com.example placeholders. Run it after you create your Apple
Developer identifiers and update the Xcode projects.
"""
from __future__ import annotations

from pathlib import Path
import sys

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
    "DEVELOPMENT_TEAM = """,
    "DEVELOPMENT_TEAM = ;",
]


def main() -> int:
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

    if problems:
        print("TestFlight readiness: NOT READY")
        for problem in problems:
            print(" -", problem)
        return 1

    print("TestFlight readiness: basic placeholders removed")
    print("Next: archive on Mac/cloud Mac and upload to App Store Connect.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
