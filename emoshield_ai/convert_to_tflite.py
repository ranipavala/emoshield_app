from pathlib import Path
import tensorflow as tf

MODEL_PATH = Path("models/best_emotion_model_5class.keras")
TFLITE_PATH = Path("models/emotion_model.tflite")

if not MODEL_PATH.exists():
    raise FileNotFoundError(
        f"Model file not found: {MODEL_PATH}. "
        "Run train_emotion_model.py first, or update MODEL_PATH."
    )

model = tf.keras.models.load_model(MODEL_PATH)

converter = tf.lite.TFLiteConverter.from_keras_model(model)
tflite_model = converter.convert()

TFLITE_PATH.write_bytes(tflite_model)

print(f"Loaded Keras model: {MODEL_PATH}")
print(f"TFLite model saved to: {TFLITE_PATH}")
print(f"File size: {TFLITE_PATH.stat().st_size / 1024:.2f} KB")