from pathlib import Path
import random
import numpy as np
import tensorflow as tf
from PIL import Image

MODEL_PATH = Path("models/best_emotion_model.keras")
TEST_DIR = Path("data/archive/test")

CLASS_NAMES = ['angry', 'disgust', 'fear', 'happy', 'neutral', 'sad', 'surprise']
IMG_SIZE = (48, 48)

model = tf.keras.models.load_model(MODEL_PATH)

# Collect a few random images from test set
all_images = []
for class_name in CLASS_NAMES:
    class_dir = TEST_DIR / class_name
    for img_path in class_dir.glob("*"):
        all_images.append((img_path, class_name))

sample_images = random.sample(all_images, 10)

def preprocess_image(img_path):
    img = Image.open(img_path).convert("L")
    img = img.resize(IMG_SIZE)
    img_array = np.array(img, dtype=np.float32)
    img_array = np.expand_dims(img_array, axis=-1)   # (48,48,1)
    img_array = np.expand_dims(img_array, axis=0)    # (1,48,48,1)
    return img_array

for img_path, true_label in sample_images:
    img_array = preprocess_image(img_path)
    prediction = model.predict(img_array, verbose=0)
    predicted_index = np.argmax(prediction)
    predicted_label = CLASS_NAMES[predicted_index]
    confidence = float(np.max(prediction))

    print(f"File: {img_path.name}")
    print(f"True label: {true_label}")
    print(f"Predicted: {predicted_label}")
    print(f"Confidence: {confidence:.4f}")
    print("-" * 40)