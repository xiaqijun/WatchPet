#!/usr/bin/env python3
"""WatchPet package tool.

Commands:
  validate <path>         Validate a .watchpet zip or unpacked package folder.
  pack <source> <output>  Pack an unpacked package folder into .watchpet.
  unpack <package> <dir>  Unpack a .watchpet package safely.
  scaffold <dir>          Create a minimal package folder skeleton.
"""
from __future__ import annotations

import argparse
import json
import shutil
import struct
import sys
import tempfile
import zipfile
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable

FORMAT = "watchpet"
SUPPORTED_FORMAT_VERSIONS = {"1.0.0"}
REQUIRED_ACTIONS = ["idle", "happy", "hungry", "eat", "sleep", "pet", "sad", "levelUp"]
MAX_CANVAS_SIZE = 512
MAX_PACKAGE_BYTES = 25 * 1024 * 1024
MAX_FRAME_BYTES = 512 * 1024
PNG_SIGNATURE = b"\x89PNG\r\n\x1a\n"


@dataclass
class ValidationIssue:
    level: str
    message: str


class WatchPetError(Exception):
    pass


def read_json(path: Path) -> dict:
    try:
        return json.loads(path.read_text(encoding="utf-8-sig"))
    except json.JSONDecodeError as exc:
        raise WatchPetError(f"Invalid JSON: {path}: {exc}") from exc


def png_info(path: Path) -> tuple[int, int, int]:
    data = path.read_bytes()
    if len(data) < 33 or not data.startswith(PNG_SIGNATURE):
        raise WatchPetError(f"Not a PNG file: {path}")
    if data[12:16] != b"IHDR":
        raise WatchPetError(f"PNG missing IHDR: {path}")
    width, height = struct.unpack(">II", data[16:24])
    color_type = data[25]
    return width, height, color_type


def iter_files(root: Path) -> Iterable[Path]:
    for p in root.rglob("*"):
        if p.is_file():
            yield p


def ensure_inside(root: Path, child: Path) -> None:
    root_resolved = root.resolve()
    child_resolved = child.resolve()
    if root_resolved != child_resolved and root_resolved not in child_resolved.parents:
        raise WatchPetError(f"Unsafe path outside target: {child}")


def unpack_zip(package_path: Path, dest: Path) -> None:
    dest.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(package_path) as zf:
        for member in zf.infolist():
            target = dest / member.filename
            ensure_inside(dest, target)
            if member.is_dir():
                target.mkdir(parents=True, exist_ok=True)
                continue
            target.parent.mkdir(parents=True, exist_ok=True)
            with zf.open(member) as src, target.open("wb") as out:
                shutil.copyfileobj(src, out)


def materialize_package(path: Path) -> tuple[Path, tempfile.TemporaryDirectory | None]:
    if path.is_dir():
        return path, None
    if path.is_file():
        tmp = tempfile.TemporaryDirectory(prefix="watchpet-")
        dest = Path(tmp.name)
        unpack_zip(path, dest)
        return dest, tmp
    raise WatchPetError(f"Path does not exist: {path}")


def validate_package(path: Path) -> list[ValidationIssue]:
    issues: list[ValidationIssue] = []
    root, tmp = materialize_package(path)
    try:
        if path.is_file() and path.stat().st_size > MAX_PACKAGE_BYTES:
            issues.append(ValidationIssue("error", f"Package too large: {path.stat().st_size} bytes"))

        manifest_path = root / "manifest.json"
        if not manifest_path.exists():
            return [ValidationIssue("error", "manifest.json is missing")]

        manifest = read_json(manifest_path)
        if manifest.get("format") != FORMAT:
            issues.append(ValidationIssue("error", f"format must be {FORMAT!r}"))
        if manifest.get("formatVersion") not in SUPPORTED_FORMAT_VERSIONS:
            issues.append(ValidationIssue("error", f"Unsupported formatVersion: {manifest.get('formatVersion')!r}"))

        for key in ["id", "name", "species", "style", "animations"]:
            if key not in manifest:
                issues.append(ValidationIssue("error", f"manifest missing required key: {key}"))

        canvas = manifest.get("canvas", {})
        width = canvas.get("width")
        height = canvas.get("height")
        if not isinstance(width, int) or not isinstance(height, int):
            issues.append(ValidationIssue("error", "canvas.width and canvas.height must be integers"))
        elif width <= 0 or height <= 0 or width > MAX_CANVAS_SIZE or height > MAX_CANVAS_SIZE:
            issues.append(ValidationIssue("error", f"canvas size out of range: {width}x{height}"))

        preview = manifest.get("preview")
        if preview and not (root / preview).exists():
            issues.append(ValidationIssue("warning", f"preview file missing: {preview}"))
        icon = manifest.get("icon")
        if icon and not (root / icon).exists():
            issues.append(ValidationIssue("warning", f"icon file missing: {icon}"))

        animations = manifest.get("animations", {})
        if not isinstance(animations, dict):
            issues.append(ValidationIssue("error", "animations must be an object"))
            return issues

        for action in REQUIRED_ACTIONS:
            spec = animations.get(action)
            if not isinstance(spec, dict):
                issues.append(ValidationIssue("error", f"required animation missing: {action}"))
                continue
            rel = spec.get("path")
            fps = spec.get("fps")
            loop = spec.get("loop")
            if not isinstance(rel, str):
                issues.append(ValidationIssue("error", f"{action}.path must be a string"))
                continue
            if not isinstance(fps, int) or fps <= 0 or fps > 30:
                issues.append(ValidationIssue("error", f"{action}.fps must be an integer between 1 and 30"))
            if not isinstance(loop, bool):
                issues.append(ValidationIssue("error", f"{action}.loop must be a boolean"))

            action_dir = root / rel
            ensure_inside(root, action_dir)
            if not action_dir.exists() or not action_dir.is_dir():
                issues.append(ValidationIssue("error", f"animation directory missing: {rel}"))
                continue
            frames = sorted(action_dir.glob("*.png"))
            if not frames:
                issues.append(ValidationIssue("error", f"animation has no PNG frames: {action}"))
                continue
            if len(frames) > 24:
                issues.append(ValidationIssue("warning", f"animation has many frames ({len(frames)}): {action}"))
            for frame in frames:
                if frame.stat().st_size > MAX_FRAME_BYTES:
                    issues.append(ValidationIssue("warning", f"large frame file: {frame.relative_to(root)}"))
                try:
                    fw, fh, color_type = png_info(frame)
                except WatchPetError as exc:
                    issues.append(ValidationIssue("error", str(exc)))
                    continue
                if width and height and (fw != width or fh != height):
                    issues.append(ValidationIssue("warning", f"frame size {fw}x{fh} differs from canvas {width}x{height}: {frame.relative_to(root)}"))
                if color_type not in (4, 6):
                    issues.append(ValidationIssue("warning", f"PNG has no alpha channel: {frame.relative_to(root)}"))

        for f in iter_files(root):
            rel = f.relative_to(root).as_posix()
            if ".." in Path(rel).parts:
                issues.append(ValidationIssue("error", f"unsafe relative path: {rel}"))

        return issues
    finally:
        if tmp:
            tmp.cleanup()


def has_errors(issues: list[ValidationIssue]) -> bool:
    return any(i.level == "error" for i in issues)


def print_issues(issues: list[ValidationIssue]) -> None:
    if not issues:
        print("OK: watchpet package is valid")
        return
    for issue in issues:
        print(f"{issue.level.upper()}: {issue.message}")


def pack_package(source: Path, output: Path, force: bool = False) -> None:
    if not source.is_dir():
        raise WatchPetError(f"Source must be a directory: {source}")
    issues = validate_package(source)
    print_issues(issues)
    if has_errors(issues):
        raise WatchPetError("Refusing to pack invalid package")
    if output.exists() and not force:
        raise WatchPetError(f"Output exists, use --force to overwrite: {output}")
    output.parent.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(output, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=9) as zf:
        for f in sorted(iter_files(source)):
            zf.write(f, f.relative_to(source).as_posix())
    print(f"Packed: {output}")


def scaffold_package(dest: Path, force: bool = False) -> None:
    if dest.exists() and any(dest.iterdir()) and not force:
        raise WatchPetError(f"Destination is not empty, use --force: {dest}")
    dest.mkdir(parents=True, exist_ok=True)
    sprites = dest / "sprites"
    for action in REQUIRED_ACTIONS:
        (sprites / action).mkdir(parents=True, exist_ok=True)
    manifest = {
        "format": FORMAT,
        "formatVersion": "1.0.0",
        "id": "example-pet-001",
        "name": "Example Pet",
        "species": "cat",
        "style": "pixel-cute",
        "author": "WatchPet",
        "preview": "preview.png",
        "icon": "icon.png",
        "canvas": {"width": 160, "height": 160, "scale": 2},
        "animations": {action: {"path": f"sprites/{action}", "fps": 4, "loop": action not in {"eat", "pet", "levelUp"}} for action in REQUIRED_ACTIONS},
    }
    (dest / "manifest.json").write_text(json.dumps(manifest, indent=2, ensure_ascii=False), encoding="utf-8")
    print(f"Scaffolded package folder: {dest}")


def cmd_validate(args: argparse.Namespace) -> int:
    issues = validate_package(Path(args.path))
    print_issues(issues)
    return 1 if has_errors(issues) else 0


def cmd_pack(args: argparse.Namespace) -> int:
    pack_package(Path(args.source), Path(args.output), force=args.force)
    return 0


def cmd_unpack(args: argparse.Namespace) -> int:
    package = Path(args.package)
    dest = Path(args.dest)
    if dest.exists() and any(dest.iterdir()) and not args.force:
        raise WatchPetError(f"Destination is not empty, use --force: {dest}")
    if dest.exists() and args.force:
        shutil.rmtree(dest)
    unpack_zip(package, dest)
    issues = validate_package(dest)
    print_issues(issues)
    if has_errors(issues):
        return 1
    print(f"Unpacked: {dest}")
    return 0


def cmd_scaffold(args: argparse.Namespace) -> int:
    scaffold_package(Path(args.dest), force=args.force)
    return 0


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Create and validate WatchPet .watchpet packages")
    sub = parser.add_subparsers(dest="command", required=True)

    p = sub.add_parser("validate", help="validate a .watchpet file or unpacked folder")
    p.add_argument("path")
    p.set_defaults(func=cmd_validate)

    p = sub.add_parser("pack", help="pack a folder into a .watchpet zip")
    p.add_argument("source")
    p.add_argument("output")
    p.add_argument("--force", action="store_true")
    p.set_defaults(func=cmd_pack)

    p = sub.add_parser("unpack", help="unpack a .watchpet zip safely")
    p.add_argument("package")
    p.add_argument("dest")
    p.add_argument("--force", action="store_true")
    p.set_defaults(func=cmd_unpack)

    p = sub.add_parser("scaffold", help="create an empty watchpet folder skeleton")
    p.add_argument("dest")
    p.add_argument("--force", action="store_true")
    p.set_defaults(func=cmd_scaffold)

    return parser


def main(argv: list[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)
    try:
        return args.func(args)
    except WatchPetError as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
