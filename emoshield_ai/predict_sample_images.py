from pathlib import Path
import random

import numpy as np
import tensorflow as tf
from PIL import Image

MODEL_PATH = Path("models/best_emotion_model_5class.keras")
TEST_DIR = Path("data/archive/test")

CLASS_NAMES = ["angry", "happy", "neutral", "sad", "surprise"]
IMG_SIZE = (48, 48)

if not MODEL_PATH.exists():
    raise FileNotFoundError(f"Model not found: {MODEL_PATH}")

model = tf.keras.models.load_model(MODEL_PATH)

all_images: list[tuple[Path, str]] = []
for class_name in CLASS_NAMES:
    class_dir = TEST_DIR / class_name
    if not class_dir.exists():
        raise FileNotFoundError(f"Missing test folder: {class_dir}")

    for img_path in class_dir.glob("*"):
        if img_path.suffix.lower() in {".jpg", ".jpeg", ".png", ".bmp", ".webp"}:
            all_images.append((img_path, class_name))

if not all_images:
    raise ValueError("No test images found.")

sample_count = min(10, len(all_images))
sample_images = random.sample(all_images, sample_count)


def preprocess_image(img_path: Path) -> np.ndarray:
    image = Image.open(img_path).convert("L")
    image = image.resize(IMG_SIZE)
    image_array = np.array(image, dtype=np.float32) / 255.0
    image_array = np.expand_dims(image_array, axis=-1)  # (48, 48, 1)
    image_array = np.expand_dims(image_array, axis=0)   # (1, 48, 48, 1)
    return image_array


for img_path, true_label in sample_images:
    img_array = preprocess_image(img_path)
    prediction = model.predict(img_array, verbose=0)[0]

    predicted_index = int(np.argmax(prediction))
    predicted_label = CLASS_NAMES[predicted_index]
    confidence = float(np.max(prediction))

    print(f"File: {img_path.name}")
    print(f"True label: {true_label}")
    print(f"Predicted: {predicted_label}")
    print(f"Confidence: {confidence:.4f}")
    print(f"Raw probs: {np.round(prediction, 4).tolist()}")
    print("-" * 40)