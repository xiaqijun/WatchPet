#!/usr/bin/env python3
"""Generate a local WatchPet package from a reference image.

This is an offline MVP for the AI-generation flow: it turns one pet/photo image
into a valid 8-action .watchpet package with simple motion/effect variants. It
is intentionally provider-free so it can run without API keys on Windows. A real
AI provider can later replace render_frame() while keeping the same package
contract.
"""
from __future__ import annotations

import argparse
import json
import shutil
import sys
import tempfile
from pathlib import Path

try:
    from PIL import Image, ImageEnhance, ImageOps
except ImportError:  # pragma: no cover - optional user dependency
    Image = None
    ImageEnhance = None
    ImageOps = None

ROOT = Path(__file__).resolve().parents[1]
ACTIONS = ["idle", "happy", "hungry", "eat", "sleep", "pet", "sad", "levelUp"]
FRAME_COUNTS = {"idle": 4, "happy": 6, "hungry": 4, "eat": 6, "sleep": 4, "pet": 6, "sad": 4, "levelUp": 8}


def slugify(value: str) -> str:
    allowed = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_"
    slug = "".join(ch if ch in allowed else "-" for ch in value.strip())
    return slug.strip("-") or "generated-pet"


def write_manifest(package_dir: Path, pet_id: str, name: str, species: str, style: str, canvas: int) -> None:
    manifest = {
        "format": "watchpet",
        "formatVersion": "1.0.0",
        "id": pet_id,
        "name": name,
        "species": species,
        "style": style,
        "author": "WatchPet local generator",
        "preview": "preview.png",
        "icon": "icon.png",
        "canvas": {"width": canvas, "height": canvas, "scale": 2},
        "animations": {
            action: {"path": f"sprites/{action}", "fps": 4 if action != "levelUp" else 6, "loop": action not in {"eat", "pet", "levelUp"}}
            for action in ACTIONS
        },
    }
    (package_dir / "manifest.json").write_text(json.dumps(manifest, ensure_ascii=False, indent=2), encoding="utf-8")


def load_reference(source: Path, canvas: int):
    if Image is None:
        raise SystemExit("Pillow is required for image generation. Install with: python -m pip install pillow")
    img = Image.open(source).convert("RGBA")
    img.thumbnail((int(canvas * 0.82), int(canvas * 0.82)), Image.Resampling.LANCZOS)
    return img


def paste_center(canvas_img, sprite, dx: int = 0, dy: int = 0):
    x = (canvas_img.width - sprite.width) // 2 + dx
    y = (canvas_img.height - sprite.height) // 2 + dy
    canvas_img.alpha_composite(sprite, (x, y))


def tint(sprite, color, alpha: float):
    overlay = Image.new("RGBA", sprite.size, color)
    base = Image.alpha_composite(sprite, Image.blend(Image.new("RGBA", sprite.size, (0, 0, 0, 0)), overlay, alpha))
    base.putalpha(sprite.getchannel("A"))
    return base


def render_frame(reference, action: str, index: int, total: int, canvas: int):
    frame = Image.new("RGBA", (canvas, canvas), (0, 0, 0, 0))
    sprite = reference.copy()
    phase = index / max(total - 1, 1)
    dx = 0
    dy = 0

    if action == "idle":
        dy = -2 if index % 2 else 2
    elif action == "happy":
        sprite = ImageEnhance.Color(sprite).enhance(1.25)
        dy = -6 if index % 2 else 1
    elif action == "hungry":
        sprite = ImageEnhance.Brightness(sprite).enhance(0.82)
        dx = -2 if index % 2 else 2
    elif action == "eat":
        dy = 4 if index % 2 else 0
        snack = Image.new("RGBA", (18, 18), (255, 176, 64, 255))
        frame.alpha_composite(snack, (canvas // 2 - 9, canvas - 34 - index % 3))
    elif action == "sleep":
        sprite = ImageEnhance.Brightness(sprite).enhance(0.72)
        dy = 5
    elif action == "pet":
        sprite = ImageOps.mirror(sprite) if index % 2 else sprite
        dy = -3
    elif action == "sad":
        sprite = tint(sprite, (80, 120, 255, 90), 0.18)
        dy = 5
    elif action == "levelUp":
        sprite = ImageEnhance.Brightness(sprite).enhance(1.0 + 0.35 * phase)
        dy = -int(8 * phase)

    paste_center(frame, sprite, dx, dy)

    if action == "sleep":
        # Small Z marks; ASCII-safe but visually clear.
        for n in range(3):
            z = Image.new("RGBA", (10 + n * 3, 10 + n * 3), (120, 180, 255, 150))
            frame.alpha_composite(z, (canvas - 44 + n * 9, 24 - index % 2))
    elif action == "levelUp":
        sparkle = Image.new("RGBA", (8, 8), (255, 240, 120, 220))
        frame.alpha_composite(sparkle, (20 + (index * 13) % (canvas - 40), 18 + (index * 7) % 42))

    return frame


def generate_unpacked(source: Path, package_dir: Path, pet_id: str, name: str, species: str, style: str, canvas: int) -> None:
    package_dir.mkdir(parents=True, exist_ok=True)
    write_manifest(package_dir, pet_id, name, species, style, canvas)
    reference = load_reference(source, canvas)

    for action in ACTIONS:
        action_dir = package_dir / "sprites" / action
        action_dir.mkdir(parents=True, exist_ok=True)
        total = FRAME_COUNTS[action]
        for i in range(total):
            frame = render_frame(reference, action, i, total, canvas)
            frame.save(action_dir / f"{i:03d}.png")

    shutil.copyfile(package_dir / "sprites" / "idle" / "000.png", package_dir / "preview.png")
    shutil.copyfile(package_dir / "sprites" / "idle" / "000.png", package_dir / "icon.png")


def pack(package_dir: Path, output: Path) -> None:
    sys.path.insert(0, str(ROOT / "scripts"))
    import watchpet_tool  # type: ignore

    watchpet_tool.pack_package(package_dir, output, force=True)


def main(argv=None) -> int:
    parser = argparse.ArgumentParser(description="Generate a local .watchpet package from one image")
    parser.add_argument("source_image", type=Path, help="Pet/photo image used as the reference")
    parser.add_argument("output", type=Path, help="Output .watchpet path")
    parser.add_argument("--name", default="Generated Pet")
    parser.add_argument("--id", default=None)
    parser.add_argument("--species", default="pet")
    parser.add_argument("--style", default="local-photo-mvp")
    parser.add_argument("--canvas", type=int, default=160)
    parser.add_argument("--keep-unpacked", type=Path, default=None, help="Optional folder to keep the unpacked package")
    args = parser.parse_args(argv)

    if not args.source_image.exists():
        raise SystemExit(f"Source image not found: {args.source_image}")
    pet_id = args.id or slugify(args.name).lower()

    if args.keep_unpacked:
        if args.keep_unpacked.exists():
            shutil.rmtree(args.keep_unpacked)
        generate_unpacked(args.source_image, args.keep_unpacked, pet_id, args.name, args.species, args.style, args.canvas)
        pack(args.keep_unpacked, args.output)
    else:
        with tempfile.TemporaryDirectory(prefix="watchpet-generated-") as tmp:
            package_dir = Path(tmp) / pet_id
            generate_unpacked(args.source_image, package_dir, pet_id, args.name, args.species, args.style, args.canvas)
            pack(package_dir, args.output)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
