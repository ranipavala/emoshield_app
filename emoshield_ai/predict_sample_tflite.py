from pathlib import Path
import random
import numpy as np
from PIL import Image
import tensorflow as tf

TFLITE_MODEL_PATH = Path("models/emotion_model.tflite")
TEST_DIR = Path("data/archive/test")
CLASS_NAMES = ['angry', 'disgust', 'fear', 'happy', 'neutral', 'sad', 'surprise']
IMG_SIZE = (48, 48)

# Load TFLite model
interpreter = tf.lite.Interpreter(model_path=str(TFLITE_MODEL_PATH))
interpreter.allocate_tensors()

input_details = interpreter.get_input_details()
output_details = interpreter.get_output_details()

print("Input details:", input_details)
print("Output details:", output_details)

# Collect random test images
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
    input_data = preprocess_image(img_path)

    interpreter.set_tensor(input_details[0]['index'], input_data)
    interpreter.invoke()
    output_data = interpreter.get_tensor(output_details[0]['index'])

    predicted_index = int(np.argmax(output_data))
    predicted_label = CLASS_NAMES[predicted_index]
    confidence = float(np.max(output_data))

    print(f"File: {img_path.name}")
    print(f"True label: {true_label}")
    print(f"Predicted: {predicted_label}")
    print(f"Confidence: {confidence:.4f}")
    print("-" * 40)