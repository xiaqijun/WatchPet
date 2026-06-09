#!/usr/bin/env python3
from pathlib import Path
import json

root = Path(__file__).resolve().parents[1]
required = [
    'README.md',
    'LICENSE',
    'WatchPet.xcodeproj/project.pbxproj',
    'WatchPetCompanion.xcodeproj/project.pbxproj',
    'WatchPet/WatchPetApp.swift',
    'WatchPet/WatchCompanionSyncManager.swift',
    'WatchPet/ImportedPetPackage.swift',
    'WatchPet/WatchPetResourceStore.swift',
    'WatchPetCompanion/WatchPetCompanionApp.swift',
    'WatchPetCompanion/Models/PetPackage.swift',
    'WatchPetCompanion/Services/WatchPetPackageLoader.swift',
    'WatchPetCompanion/Services/CompanionWatchSyncManager.swift',
    'WatchPetCompanion/Services/PetPackageLibrary.swift',
    'WatchPetCompanion/Views/ContentView.swift',
    'WatchPetCompanion/Views/SpriteAnimationView.swift',
    'WatchPetCompanion/Resources/mochi.watchpet/manifest.json',
    'WatchPet/ContentView.swift',
    'WatchPet/PetModel.swift',
    'WatchPet/PetStore.swift',
    'WatchPet/PetSpriteView.swift',
    'WatchPet/HealthStepProvider.swift',
    'WatchPet/Assets.xcassets/Contents.json',
    'WatchPet/WatchPetAssets/manifest.example.json',
    'scripts/watchpet_tool.py',
    'scripts/generate_watchpet_local.py',
    'WatchPetWidget/WatchPetWidget.swift',
    'docs/10_IWATCH_TESTING_GUIDE.md',
    'docs/00_MASTER_PLAN.md',
    'docs/01_PRD.md',
    'docs/02_WATCHPET_PACKAGE_SPEC.md',
    'docs/03_AI_GENERATION_PLAN.md',
    'docs/04_DEVELOPMENT_PLAN.md',
    'docs/05_DELIVERY_CHECKLIST.md',
]
missing = [p for p in required if not (root / p).exists()]
if missing:
    print('Missing required files:')
    for p in missing:
        print(' -', p)
    raise SystemExit(1)

manifest_path = root / 'WatchPet/WatchPetAssets/manifest.example.json'
manifest = json.loads(manifest_path.read_text(encoding='utf-8-sig'))
required_actions = {'idle','happy','hungry','eat','sleep','pet','sad','levelUp'}
actions = set(manifest.get('animations', {}).keys())
if not required_actions.issubset(actions):
    print('Manifest missing actions:', sorted(required_actions - actions))
    raise SystemExit(1)

assets = root / 'WatchPet/Assets.xcassets'
missing_assets = []
for action in required_actions:
    max_frames = 8 if action == 'levelUp' else (6 if action in {'happy','eat','pet'} else 4)
    for i in range(max_frames):
        if not (assets / f'{action}_{i}.imageset' / f'{action}_{i}.png').exists():
            missing_assets.append(f'{action}_{i}')
if missing_assets:
    print('Missing sprite assets:', missing_assets[:20])
    raise SystemExit(1)

print('WatchPet repository validation passed.')
print('Root:', root)
