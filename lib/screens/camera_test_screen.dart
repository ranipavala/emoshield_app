import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class CameraTestScreen extends StatefulWidget {
  const CameraTestScreen({super.key});

  @override
  State<CameraTestScreen> createState() => _CameraTestScreenState();
}

class _CameraTestScreenState extends State<CameraTestScreen> {
  static const _modelAssetPath = 'assets/models/emotion_model.tflite';
  static const _labels = [
    'angry',
    'happy',
    'neutral',
    'sad',
    'surprise',
  ];

  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  List<CameraDescription> _cameras = [];

  final _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      performanceMode: FaceDetectorMode.fast,
      enableContours: false,
      enableLandmarks: false,
    ),
  );

  Interpreter? _interpreter;
  bool _isAnalyzing = false;
  String? _errorMessage;
  String? _predictedLabel;
  double? _confidence;
  List<double>? _probabilities;
  Uint8List? _faceCropPreviewBytes;
  Uint8List? _modelInputPreviewBytes;

  @override
  void initState() {
    super.initState();
    _setupCamera();
  }

  Future<void> _setupCamera() async {
    try {
      _cameras = await availableCameras();

      if (_cameras.isEmpty) {
        debugPrint('No cameras found');
        return;
      }

      final frontCamera = _cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras.first,
      );

      _controller = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      _initializeControllerFuture = _controller!.initialize();
      await _initializeControllerFuture;

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('Camera setup error: $e');
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _interpreter?.close();
    _faceDetector.close();
    super.dispose();
  }

  Future<Interpreter> _loadInterpreter() async {
    if (_interpreter != null) {
      return _interpreter!;
    }

    _interpreter = await Interpreter.fromAsset(_modelAssetPath);
    return _interpreter!;
  }

  Future<void> _analyzeCurrentFrame() async {
    final controller = _controller;
    if (controller == null || _isAnalyzing) return;

    setState(() {
      _isAnalyzing = true;
      _errorMessage = null;
      _predictedLabel = null;
      _confidence = null;
      _probabilities = null;
      _faceCropPreviewBytes = null;
      _modelInputPreviewBytes = null;
    });

    try {
      await _initializeControllerFuture;

      final capturedFile = await controller.takePicture();
      final imageBytes = await File(capturedFile.path).readAsBytes();
      final decodedImage = img.decodeImage(imageBytes);

      if (decodedImage == null) {
        throw Exception('Could not decode captured image.');
      }

      final inputImage = InputImage.fromFilePath(capturedFile.path);
      final faces = await _faceDetector.processImage(inputImage);

      if (faces.isEmpty) {
        throw Exception('No face detected in camera frame.');
      }

      final face = _selectLargestFace(faces);
      final faceCrop = _cropFace(decodedImage, face.boundingBox);

      if (faceCrop == null) {
        throw Exception('Detected face crop is invalid.');
      }

      final modelInputImage = _buildModelInputImage(faceCrop);
      final inputTensor = _buildInputTensor(modelInputImage);

      final interpreter = await _loadInterpreter();
      final output = List.generate(1, (_) => List.filled(_labels.length, 0.0));
      interpreter.run(inputTensor, output);

      final probabilities = output.first.map((value) => value.toDouble()).toList();
      final bestIndex = _indexOfMax(probabilities);

      if (!mounted) return;

      setState(() {
        _faceCropPreviewBytes = Uint8List.fromList(img.encodeJpg(faceCrop));
        _modelInputPreviewBytes = Uint8List.fromList(img.encodeJpg(modelInputImage));
        _predictedLabel = _labels[bestIndex];
        _confidence = probabilities[bestIndex];
        _probabilities = probabilities;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
        });
      }
    }
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
    final x = boundingBox.left.floor().clamp(0, sourceImage.width - 1);
    final y = boundingBox.top.floor().clamp(0, sourceImage.height - 1);
    final right = boundingBox.right.ceil().clamp(x + 1, sourceImage.width);
    final bottom = boundingBox.bottom.ceil().clamp(y + 1, sourceImage.height);

    final width = right - x;
    final height = bottom - y;

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

  Widget _buildDebugPreview(String title, Uint8List? bytes, {double size = 120}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Container(
          width: size,
          height: size,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(10),
          ),
          child: bytes == null
              ? const Center(child: Text('No data'))
              : Image.memory(bytes, fit: BoxFit.cover),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Camera Test'),
      ),
      body: controller == null
          ? const Center(child: CircularProgressIndicator())
          : FutureBuilder<void>(
              future: _initializeControllerFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  return Column(
                    children: [
                      Expanded(
                        child: CameraPreview(controller),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _isAnalyzing ? null : _analyzeCurrentFrame,
                                child: Text(
                                  _isAnalyzing
                                      ? 'Analyzing...'
                                      : 'Capture + Analyze Current Frame',
                                ),
                              ),
                            ),
                            if (_isAnalyzing) const LinearProgressIndicator(),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                _buildDebugPreview(
                                  'Face crop (before preprocessing)',
                                  _faceCropPreviewBytes,
                                ),
                                const SizedBox(width: 12),
                                _buildDebugPreview(
                                  'Model input (48x48 grayscale)',
                                  _modelInputPreviewBytes,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (_errorMessage != null)
                              Text(
                                'Error: $_errorMessage',
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            if (_errorMessage == null && _probabilities != null) ...[
                              Text(
                                'Predicted: $_predictedLabel',
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                              Text(
                                'Confidence: ${((_confidence ?? 0) * 100).toStringAsFixed(2)}%',
                              ),
                              const SizedBox(height: 4),
                              for (var i = 0; i < _labels.length; i++)
                                Text(
                                  '${_labels[i]}: ${_probabilities![i].toStringAsFixed(6)}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  );
                } else if (snapshot.hasError) {
                  return Center(
                    child: Text('Camera error: ${snapshot.error}'),
                  );
                } else {
                  return const Center(child: CircularProgressIndicator());
                }
              },
            ),
    );
  }
}