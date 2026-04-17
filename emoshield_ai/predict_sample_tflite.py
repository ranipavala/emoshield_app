from pathlib import Path
import random

import numpy as np
from PIL import Image
import tensorflow as tf

TFLITE_MODEL_PATH = Path("models/emotion_model.tflite")
TEST_DIR = Path("data/archive/test")
CLASS_NAMES = ["angry", "happy", "neutral", "sad", "surprise"]
IMG_SIZE = (48, 48)

if not TFLITE_MODEL_PATH.exists():
    raise FileNotFoundError(f"TFLite model not found: {TFLITE_MODEL_PATH}")

interpreter = tf.lite.Interpreter(model_path=str(TFLITE_MODEL_PATH))
interpreter.allocate_tensors()

input_details = interpreter.get_input_details()
output_details = interpreter.get_output_details()

print("Input details:", input_details)
print("Output details:", output_details)

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
    input_data = preprocess_image(img_path)

    interpreter.set_tensor(input_details[0]["index"], input_data)
    interpreter.invoke()
    output_data = interpreter.get_tensor(output_details[0]["index"])[0]

    predicted_index = int(np.argmax(output_data))
    predicted_label = CLASS_NAMES[predicted_index]
    confidence = float(np.max(output_data))

    print(f"File: {img_path.name}")
    print(f"True label: {true_label}")
    print(f"Predicted: {predicted_label}")
    print(f"Confidence: {confidence:.4f}")
    print(f"Raw probs: {np.round(output_data, 4).tolist()}")
    print("-" * 40)