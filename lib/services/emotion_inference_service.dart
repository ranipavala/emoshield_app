import 'dart:typed_data';
import 'dart:ui';

import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class EmotionInferenceResult {
  final String emotionLabel;
  final double confidenceScore;
  final List<double> probabilities;

  const EmotionInferenceResult({
    required this.emotionLabel,
    required this.confidenceScore,
    required this.probabilities,
  });
}

class EmotionInferenceService {
  static const String _modelAssetPath = 'assets/models/emotion_model.tflite';

  // IMPORTANT: Must match training class order in train_emotion_model.py.
  static const List<String> labels = <String>[
    'angry',
    'happy',
    'neutral',
    'sad',
    'surprise',
  ];

  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      performanceMode: FaceDetectorMode.fast,
      enableContours: false,
      enableLandmarks: false,
    ),
  );

  Interpreter? _interpreter;

  Future<void> initialize() async {
    _interpreter ??= await Interpreter.fromAsset(_modelAssetPath);
  }

  Future<EmotionInferenceResult?> inferFromCapturedImage({
    required String imagePath,
    required Uint8List jpegBytes,
    bool tryMirroredVariant = false,
  }) async {
    await initialize();

    final decodedImage = img.decodeImage(jpegBytes);
    if (decodedImage == null) {
      return null;
    }

    final orientedImage = img.bakeOrientation(decodedImage);

    final inputImage = InputImage.fromFilePath(imagePath);
    final faces = await _faceDetector.processImage(inputImage);
    if (faces.isEmpty) {
      return null;
    }

    final largestFace = _selectLargestFace(faces);
    final faceCrop = _cropFace(orientedImage, largestFace.boundingBox);
    if (faceCrop == null) {
      return null;
    }

    final directResult = _runModel(faceCrop);
    if (!tryMirroredVariant) {
      return directResult;
    }

    final mirroredFace = img.flipHorizontal(faceCrop);
    final mirroredResult = _runModel(mirroredFace);

    return mirroredResult.confidenceScore > directResult.confidenceScore
        ? mirroredResult
        : directResult;
  }

  EmotionInferenceResult _runModel(img.Image faceCrop) {
    final modelInputImage = _buildModelInputImage(faceCrop);
    final inputTensor = _buildInputTensor(modelInputImage);

    final output = List.generate(1, (_) => List.filled(labels.length, 0.0));
    _interpreter!.run(inputTensor, output);

    final probabilities = output.first.map((value) => value.toDouble()).toList();
    final bestIndex = _indexOfMax(probabilities);

    return EmotionInferenceResult(
      emotionLabel: labels[bestIndex],
      confidenceScore: probabilities[bestIndex],
      probabilities: probabilities,
    );
  }

  Face _selectLargestFace(List<Face> faces) {
    var largest = faces.first;
    var largestArea = _area(largest.boundingBox);

    for (final face in faces.skip(1)) {
      final area = _area(face.boundingBox);
      if (area > largestArea) {
        largest = face;
        largestArea = area;
      }
    }

    return largest;
  }

  double _area(Rect rect) => rect.width * rect.height;

  img.Image? _cropFace(img.Image sourceImage, Rect boundingBox) {
    final paddingX = boundingBox.width * 0.12;
    final paddingY = boundingBox.height * 0.12;

    final left = (boundingBox.left - paddingX).floor();
    final top = (boundingBox.top - paddingY).floor();
    final right = (boundingBox.right + paddingX).ceil();
    final bottom = (boundingBox.bottom + paddingY).ceil();

    final x = left.clamp(0, sourceImage.width - 1);
    final y = top.clamp(0, sourceImage.height - 1);
    final safeRight = right.clamp(x + 1, sourceImage.width);
    final safeBottom = bottom.clamp(y + 1, sourceImage.height);

    final width = safeRight - x;
    final height = safeBottom - y;

    if (width <= 0 || height <= 0) {
      return null;
    }

    return img.copyCrop(
      sourceImage,
      x: x,
      y: y,
      width: width,
      height: height,
    );
  }

  img.Image _buildModelInputImage(img.Image faceCrop) {
    final grayscale = img.grayscale(faceCrop);
    return img.copyResize(
      grayscale,
      width: 48,
      height: 48,
      interpolation: img.Interpolation.linear,
    );
  }

  List<List<List<List<double>>>> _buildInputTensor(img.Image modelInputImage) {
    final input = List.generate(
      1,
      (_) => List.generate(
        48,
        (y) => List.generate(
          48,
          (x) {
            final pixel = modelInputImage.getPixel(x, y);
            final normalized = pixel.r / 255.0;
            return [normalized];
          },
        ),
      ),
    );

    return input;
  }

  int _indexOfMax(List<double> values) {
    var bestIndex = 0;
    var bestValue = values.first;

    for (var index = 1; index < values.length; index++) {
      if (values[index] > bestValue) {
        bestValue = values[index];
        bestIndex = index;
      }
    }

    return bestIndex;
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _faceDetector.close();
  }
}