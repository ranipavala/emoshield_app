from pathlib import Path
import random

import numpy as np
import tensorflow as tf

# -----------------------------
# Config
# -----------------------------
DATA_DIR = Path("data/archive")
TRAIN_DIR = DATA_DIR / "train"
TEST_DIR = DATA_DIR / "test"

CLASS_NAMES = ["angry", "happy", "neutral", "sad", "surprise"]
CLASS_TO_INDEX = {name: idx for idx, name in enumerate(CLASS_NAMES)}

IMG_SIZE = (48, 48)
BATCH_SIZE = 64
SEED = 42
VAL_SPLIT = 0.2
EPOCHS = 40

MODEL_DIR = Path("models")
MODEL_DIR.mkdir(exist_ok=True)

BEST_MODEL_PATH = MODEL_DIR / "best_emotion_model_5class.keras"
FINAL_MODEL_PATH = MODEL_DIR / "final_emotion_model_5class.keras"
TFLITE_PATH = MODEL_DIR / "emotion_model.tflite"
LABELS_PATH = MODEL_DIR / "emotion_labels_5class.txt"

AUTOTUNE = tf.data.AUTOTUNE


def collect_files_by_class(root_dir: Path, class_names: list[str]) -> dict[str, list[Path]]:
    files_by_class: dict[str, list[Path]] = {}

    for class_name in class_names:
        class_dir = root_dir / class_name
        if not class_dir.exists():
            raise FileNotFoundError(f"Missing class folder: {class_dir}")

        image_paths = [
            path
            for path in class_dir.glob("*")
            if path.suffix.lower() in {".jpg", ".jpeg", ".png", ".bmp", ".webp"}
        ]

        if not image_paths:
            raise ValueError(f"No images found for class '{class_name}' in {class_dir}")

        files_by_class[class_name] = sorted(image_paths)

    return files_by_class


def split_train_val(
    files_by_class: dict[str, list[Path]],
    val_split: float,
    seed: int,
) -> tuple[list[str], list[int], list[str], list[int]]:
    rng = random.Random(seed)

    train_paths: list[str] = []
    train_labels: list[int] = []
    val_paths: list[str] = []
    val_labels: list[int] = []

    for class_name in CLASS_NAMES:
        image_paths = files_by_class[class_name][:]
        rng.shuffle(image_paths)

        val_count = max(1, int(len(image_paths) * val_split))
        val_subset = image_paths[:val_count]
        train_subset = image_paths[val_count:]

        if not train_subset:
            raise ValueError(f"Not enough images in class '{class_name}' after split.")

        class_idx = CLASS_TO_INDEX[class_name]

        train_paths.extend([str(path) for path in train_subset])
        train_labels.extend([class_idx] * len(train_subset))

        val_paths.extend([str(path) for path in val_subset])
        val_labels.extend([class_idx] * len(val_subset))

    return train_paths, train_labels, val_paths, val_labels


def flatten_files(files_by_class: dict[str, list[Path]]) -> tuple[list[str], list[int]]:
    paths: list[str] = []
    labels: list[int] = []

    for class_name in CLASS_NAMES:
        class_idx = CLASS_TO_INDEX[class_name]
        class_files = files_by_class[class_name]
        paths.extend([str(path) for path in class_files])
        labels.extend([class_idx] * len(class_files))

    return paths, labels


def decode_and_preprocess(path: tf.Tensor, label: tf.Tensor) -> tuple[tf.Tensor, tf.Tensor]:
    image_bytes = tf.io.read_file(path)
    image = tf.io.decode_image(image_bytes, channels=1, expand_animations=False)
    image = tf.image.resize(image, IMG_SIZE)
    image = tf.cast(image, tf.float32) / 255.0
    return image, label


def build_dataset(paths: list[str], labels: list[int], training: bool) -> tf.data.Dataset:
    ds = tf.data.Dataset.from_tensor_slices((paths, labels))

    if training:
        ds = ds.shuffle(buffer_size=len(paths), seed=SEED, reshuffle_each_iteration=True)

    ds = ds.map(decode_and_preprocess, num_parallel_calls=AUTOTUNE)
    ds = ds.batch(BATCH_SIZE).prefetch(AUTOTUNE)
    return ds


def build_model(num_classes: int) -> tf.keras.Model:
    data_augmentation = tf.keras.Sequential(
        [
            tf.keras.layers.RandomFlip("horizontal"),
            tf.keras.layers.RandomRotation(0.08),
            tf.keras.layers.RandomZoom(0.10),
            tf.keras.layers.RandomContrast(0.10),
        ],
        name="augmentation",
    )

    inputs = tf.keras.Input(shape=(48, 48, 1), name="input_image")
    x = data_augmentation(inputs)

    for i, filters in enumerate([32, 64, 128]):
        x = tf.keras.layers.Conv2D(filters, 3, padding="same", use_bias=False)(x)
        x = tf.keras.layers.BatchNormalization()(x)
        x = tf.keras.layers.ReLU()(x)
        x = tf.keras.layers.Conv2D(filters, 3, padding="same", use_bias=False)(x)
        x = tf.keras.layers.BatchNormalization()(x)
        x = tf.keras.layers.ReLU()(x)
        x = tf.keras.layers.MaxPooling2D()(x)
        x = tf.keras.layers.Dropout(0.20 + i * 0.05)(x)

    x = tf.keras.layers.Conv2D(256, 3, padding="same", use_bias=False)(x)
    x = tf.keras.layers.BatchNormalization()(x)
    x = tf.keras.layers.ReLU()(x)
    x = tf.keras.layers.GlobalAveragePooling2D()(x)
    x = tf.keras.layers.Dense(128, activation="relu")(x)
    x = tf.keras.layers.Dropout(0.4)(x)

    outputs = tf.keras.layers.Dense(num_classes, activation="softmax", name="emotion_probs")(x)

    model = tf.keras.Model(inputs=inputs, outputs=outputs, name="emotion_cnn_5class")

    model.compile(
        optimizer=tf.keras.optimizers.Adam(learning_rate=1e-3),
        loss="sparse_categorical_crossentropy",
        metrics=["accuracy"],
    )

    return model


def compute_class_weights(labels: list[int], num_classes: int) -> dict[int, float]:
    counts = np.bincount(labels, minlength=num_classes)
    total = float(np.sum(counts))

    weights: dict[int, float] = {}
    for class_idx in range(num_classes):
        if counts[class_idx] == 0:
            continue
        weights[class_idx] = total / (num_classes * float(counts[class_idx]))

    return weights


def export_tflite(keras_model_path: Path, tflite_output_path: Path) -> None:
    model = tf.keras.models.load_model(keras_model_path)
    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    tflite_model = converter.convert()
    tflite_output_path.write_bytes(tflite_model)


def main() -> None:
    tf.keras.utils.set_random_seed(SEED)

    print("Using class order:", CLASS_NAMES)

    train_files_by_class = collect_files_by_class(TRAIN_DIR, CLASS_NAMES)
    test_files_by_class = collect_files_by_class(TEST_DIR, CLASS_NAMES)

    train_paths, train_labels, val_paths, val_labels = split_train_val(
        train_files_by_class,
        val_split=VAL_SPLIT,
        seed=SEED,
    )
    test_paths, test_labels = flatten_files(test_files_by_class)

    print(f"Train samples: {len(train_paths)}")
    print(f"Val samples:   {len(val_paths)}")
    print(f"Test samples:  {len(test_paths)}")

    train_ds = build_dataset(train_paths, train_labels, training=True)
    val_ds = build_dataset(val_paths, val_labels, training=False)
    test_ds = build_dataset(test_paths, test_labels, training=False)

    class_weights = compute_class_weights(train_labels, num_classes=len(CLASS_NAMES))
    print("Class weights:", class_weights)

    model = build_model(num_classes=len(CLASS_NAMES))
    model.summary()

    callbacks = [
        tf.keras.callbacks.EarlyStopping(
            monitor="val_loss",
            patience=8,
            restore_best_weights=True,
        ),
        tf.keras.callbacks.ReduceLROnPlateau(
            monitor="val_loss",
            factor=0.5,
            patience=3,
            min_lr=1e-6,
        ),
        tf.keras.callbacks.ModelCheckpoint(
            filepath=str(BEST_MODEL_PATH),
            monitor="val_accuracy",
            mode="max",
            save_best_only=True,
        ),
    ]

    history = model.fit(
        train_ds,
        validation_data=val_ds,
        epochs=EPOCHS,
        callbacks=callbacks,
        class_weight=class_weights,
    )

    best_model = tf.keras.models.load_model(BEST_MODEL_PATH)

    test_loss, test_acc = best_model.evaluate(test_ds, verbose=1)
    print(f"Test Loss: {test_loss:.4f}")
    print(f"Test Accuracy: {test_acc:.4f}")

    best_model.save(FINAL_MODEL_PATH)

    export_tflite(BEST_MODEL_PATH, TFLITE_PATH)

    LABELS_PATH.write_text("\n".join(CLASS_NAMES), encoding="utf-8")

    print("Training complete.")
    print("Best model:", BEST_MODEL_PATH)
    print("Final model:", FINAL_MODEL_PATH)
    print("TFLite model:", TFLITE_PATH)
    print("Labels file:", LABELS_PATH)
    print("Epochs trained:", len(history.history.get("loss", [])))


if __name__ == "__main__":
    main()