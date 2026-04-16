import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class EmotionModelTestScreen extends StatefulWidget {
  const EmotionModelTestScreen({super.key});

  @override
  State<EmotionModelTestScreen> createState() => _EmotionModelTestScreenState();
}

class _EmotionModelTestScreenState extends State<EmotionModelTestScreen> {
  static const _modelAssetPath = 'assets/models/emotion_model.tflite';
  static const _sampleImageAssetPath = 'assets/images/happysample.webp';
  static const _labels = [
    'angry',
    'disgust',
    'fear',
    'happy',
    'neutral',
    'sad',
    'surprise',
  ];

  Interpreter? _interpreter;
  bool _isRunning = true;
  String? _errorMessage;
  String? _predictedLabel;
  double? _confidence;
  List<double>? _probabilities;

  @override
  void initState() {
    super.initState();
    _runTest();
  }

  @override
  void dispose() {
    _interpreter?.close();
    super.dispose();
  }

  Future<void> _runTest() async {
    setState(() {
      _isRunning = true;
      _errorMessage = null;
    });

    try {
      final interpreter = await _loadInterpreter();
      final inputTensor = await _buildInputTensor(_sampleImageAssetPath);

      final output = List.generate(1, (_) => List.filled(7, 0.0));
      interpreter.run(inputTensor, output);

      final probabilities = output.first.map((value) => value.toDouble()).toList();
      final bestIndex = _indexOfMax(probabilities);

      setState(() {
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

  Future<List<List<List<List<double>>>>> _buildInputTensor(String assetPath) async {
    final bytes = await _loadAssetBytes(assetPath);
    final decoded = img.decodeImage(bytes);

    if (decoded == null) {
      throw Exception('Could not decode image at "$assetPath".');
    }

    final grayscale = img.grayscale(decoded);
    final resized = img.copyResize(
      grayscale,
      width: 48,
      height: 48,
      interpolation: img.Interpolation.linear,
    );

    final buffer = Float32List(48 * 48);

    var index = 0;
    for (var y = 0; y < 48; y++) {
      for (var x = 0; x < 48; x++) {
        final pixel = resized.getPixel(x, y);
        buffer[index] = pixel.r / 255.0;
        index++;
      }
    }

    final tensor = List.generate(
      1,
      (_) => List.generate(
        48,
        (y) => List.generate(
          48,
          (x) => [buffer[(y * 48) + x]],
        ),
      ),
    );

    return tensor;
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
              'Sample image',
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