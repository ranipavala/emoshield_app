from pathlib import Path

DATA_DIR = Path("data/archive")
TRAIN_DIR = DATA_DIR / "train"
TEST_DIR = DATA_DIR / "test"
TARGET_CLASSES = ["angry", "happy", "neutral", "sad", "surprise"]
REMOVED_CLASSES = ["disgust", "fear"]

print("Checking dataset folders...")
print("Train dir exists:", TRAIN_DIR.exists())
print("Test dir exists:", TEST_DIR.exists())
print()

for split_name, split_dir in [("train", TRAIN_DIR), ("test", TEST_DIR)]:
    print(f"[{split_name.upper()}]")

    for class_name in TARGET_CLASSES:
        class_dir = split_dir / class_name
        if not class_dir.exists():
            print(f"  MISSING: {class_dir}")
            continue

        image_count = len(
            [
                p
                for p in class_dir.glob("*")
                if p.suffix.lower() in {".jpg", ".jpeg", ".png", ".bmp", ".webp"}
            ]
        )
        print(f"  {class_name:8s} -> {image_count} images")

    for removed_class in REMOVED_CLASSES:
        removed_dir = split_dir / removed_class
        print(f"  (ignored) {removed_class:8s} -> {'exists' if removed_dir.exists() else 'missing'}")

    print()

print("Expected class order for 5-class model:", TARGET_CLASSES)
print("Data check complete.")