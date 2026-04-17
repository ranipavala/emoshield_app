import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class EmotionModelTestScreen extends StatefulWidget {
  const EmotionModelTestScreen({super.key});

  @override
  State<EmotionModelTestScreen> createState() => _EmotionModelTestScreenState();
}

class _EmotionModelTestScreenState extends State<EmotionModelTestScreen> {
  static const _modelAssetPath = 'assets/models/emotion_model.tflite';
  static const _sampleImageAssetPath = 'assets/images/happyme.jpg';
  static const _labels = [
    'angry',
    'happy',
    'neutral',
    'sad',
    'surprise',
  ];

  final _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      performanceMode: FaceDetectorMode.fast,
      enableContours: false,
      enableLandmarks: false,
    ),
  );

  Interpreter? _interpreter;
  bool _isRunning = true;
  String? _errorMessage;
  String? _predictedLabel;
  double? _confidence;
  List<double>? _probabilities;
  Uint8List? _croppedFaceBytes;
  Uint8List? _modelInput48x48Bytes;

  @override
  void initState() {
    super.initState();
    _runTest();
  }

  @override
  void dispose() {
    _interpreter?.close();
    _faceDetector.close();
    super.dispose();
  }

  Future<void> _runTest() async {
    setState(() {
      _isRunning = true;
      _errorMessage = null;
      _predictedLabel = null;
      _confidence = null;
      _probabilities = null;
      _croppedFaceBytes = null;
      _modelInput48x48Bytes = null;
    });

    try {
      final interpreter = await _loadInterpreter();
      final sampleBytes = await _loadAssetBytes(_sampleImageAssetPath);
      final sampleImage = img.decodeImage(sampleBytes);

      if (sampleImage == null) {
        throw Exception('Could not decode image at "$_sampleImageAssetPath".');
      }

      final faces = await _detectFaces(sampleBytes);
      if (faces.isEmpty) {
        throw Exception('No face detected in happyme.jpg.');
      }

      final selectedFace = _selectLargestFace(faces);
      final croppedFace = _cropFace(sampleImage, selectedFace.boundingBox);

      if (croppedFace == null) {
        throw Exception('Face was detected, but crop bounds were invalid.');
      }

      final modelInputImage = _buildModelInputImage(croppedFace);
      final inputTensor = _buildInputTensorFromModelImage(modelInputImage);

      final output = List.generate(1, (_) => List.filled(_labels.length, 0.0));
      interpreter.run(inputTensor, output);

      final probabilities = output.first.map((value) => value.toDouble()).toList();
      final bestIndex = _indexOfMax(probabilities);

      setState(() {
        _croppedFaceBytes = Uint8List.fromList(img.encodeJpg(croppedFace));
        _modelInput48x48Bytes = Uint8List.fromList(img.encodeJpg(modelInputImage));
        _probabilities = probabilities;
        _predictedLabel = _labels[bestIndex];
        _confidence = probabilities[bestIndex];
      });
    } catch (error) {
      setState(() {
        _errorMessage = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isRunning = false;
        });
      }
    }
  }

  Future<Interpreter> _loadInterpreter() async {
    if (_interpreter != null) {
      return _interpreter!;
    }

    try {
      _interpreter = await Interpreter.fromAsset(_modelAssetPath);
      return _interpreter!;
    } catch (error) {
      throw Exception(
        'Could not load model from "$_modelAssetPath". '
        'Please verify the asset exists and is a valid TFLite file.\n$error',
      );
    }
  }

  Future<List<Face>> _detectFaces(Uint8List imageBytes) async {
    final tempImageFile = await _writeTempImage(imageBytes);
    final inputImage = InputImage.fromFilePath(tempImageFile.path);

    try {
      return await _faceDetector.processImage(inputImage);
    } catch (error) {
      throw Exception('Face detection failed.\n$error');
    }
  }

  Future<File> _writeTempImage(Uint8List bytes) async {
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/emotion_test_sample.jpg');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  Face _selectLargestFace(List<Face> faces) {
    Face largestFace = faces.first;
    var largestArea = _faceArea(largestFace.boundingBox);

    for (final face in faces.skip(1)) {
      final area = _faceArea(face.boundingBox);
      if (area > largestArea) {
        largestFace = face;
        largestArea = area;
      }
    }

    return largestFace;
  }

  double _faceArea(Rect rect) {
    return rect.width * rect.height;
  }

  img.Image? _cropFace(img.Image original, Rect boundingBox) {
    final x = boundingBox.left.floor().clamp(0, original.width - 1);
    final y = boundingBox.top.floor().clamp(0, original.height - 1);
    final right = boundingBox.right.ceil().clamp(x + 1, original.width);
    final bottom = boundingBox.bottom.ceil().clamp(y + 1, original.height);

    final width = right - x;
    final height = bottom - y;

    if (width <= 0 || height <= 0) {
      return null;
    }

    return img.copyCrop(
      original,
      x: x,
      y: y,
      width: width,
      height: height,
    );
  }

  img.Image _buildModelInputImage(img.Image faceImage) {
    final grayscale = img.grayscale(faceImage);
    return img.copyResize(
      grayscale,
      width: 48,
      height: 48,
      interpolation: img.Interpolation.linear,
    );
  }

  List<List<List<List<double>>>> _buildInputTensorFromModelImage(img.Image modelInputImage) {
    final buffer = Float32List(48 * 48);

    var index = 0;
    for (var y = 0; y < 48; y++) {
      for (var x = 0; x < 48; x++) {
        final pixel = modelInputImage.getPixel(x, y);
        buffer[index] = pixel.r / 255.0;
        index++;
      }
    }

    return List.generate(
      1,
      (_) => List.generate(
        48,
        (y) => List.generate(
          48,
          (x) => [buffer[(y * 48) + x]],
        ),
      ),
    );
  }

  Future<Uint8List> _loadAssetBytes(String assetPath) async {
    try {
      final byteData = await rootBundle.load(assetPath);
      return byteData.buffer.asUint8List();
    } catch (error) {
      throw Exception(
        'Could not load image asset from "$assetPath". '
        'Please confirm the asset file is present.\n$error',
      );
    }
  }

  int _indexOfMax(List<double> values) {
    var bestIndex = 0;
    var bestValue = values.first;

    for (var i = 1; i < values.length; i++) {
      if (values[i] > bestValue) {
        bestValue = values[i];
        bestIndex = i;
      }
    }

    return bestIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emotion Model Test'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Original sample image',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                _sampleImageAssetPath,
                height: 180,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) {
                  return Container(
                    height: 180,
                    width: double.infinity,
                    color: Colors.grey.shade200,
                    alignment: Alignment.center,
                    child: const Text('Could not load sample image.'),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Detected face crop',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Container(
              height: 140,
              width: 140,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey.shade200,
              ),
              clipBehavior: Clip.antiAlias,
              child: _croppedFaceBytes == null
                  ? const Center(child: Text('No crop yet'))
                  : Image.memory(
                      _croppedFaceBytes!,
                      fit: BoxFit.cover,
                    ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Final model input (48x48 grayscale)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Container(
              height: 140,
              width: 140,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey.shade200,
              ),
              clipBehavior: Clip.antiAlias,
              child: _modelInput48x48Bytes == null
                  ? const Center(child: Text('No 48x48 input yet'))
                  : Image.memory(
                      _modelInput48x48Bytes!,
                      fit: BoxFit.cover,
                    ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isRunning ? null : _runTest,
              child: Text(_isRunning ? 'Running...' : 'Run Test Again'),
            ),
            const SizedBox(height: 16),
            if (_isRunning) const LinearProgressIndicator(),
            if (_errorMessage != null) ...[
              const Text(
                'Error',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            ],
            if (_errorMessage == null && _probabilities != null) ...[
              Text(
                'Predicted label: $_predictedLabel',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text('Confidence: ${((_confidence ?? 0) * 100).toStringAsFixed(2)}%'),
              const SizedBox(height: 16),
              const Text(
                'Raw probabilities',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              for (var i = 0; i < _labels.length; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text('${_labels[i]}: ${_probabilities![i].toStringAsFixed(6)}'),
                ),
            ],
          ],
        ),
      ),
    );
  }
}