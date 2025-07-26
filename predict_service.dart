import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class TFLiteService {
  late Interpreter _interpreter;
  bool _modelLoaded = false;

  /// Loads the TFLite model from assets
  Future<void> loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/models/nbc_model.tflite');
      _modelLoaded = true;
      print("Model loaded successfully");
    } catch (e) {
      print(" Failed to load model: $e");
      rethrow;
    }
  }

  /// Predict match outcome by fetching stats from Firestore using team IDs
  Future<Map<String, String>> predictMatch(String teamAId, String teamBId) async {
    if (!_modelLoaded) {
      throw Exception("Model not loaded");
    }

      // Fetch Firestore data
      final docA = await FirebaseFirestore.instance.collection('teams').doc(teamAId).get();
      final docB = await FirebaseFirestore.instance.collection('teams').doc(teamBId).get();

      final dataA = docA.data()!;
      final dataB = docB.data()!;

      // Safe stat extractor
      double getStat(Map<String, dynamic> data, String key) {
        final value = data[key];
        if (value == null) {
          throw Exception("Missing '$key' in Firestore for team ${data['name'] ?? 'unknown'}");
        }
        return (value as num).toDouble();
      }
      // Extract input features
      final List<double> input = [
        getStat(dataA, 'Pts'),
        getStat(dataA, 'GD'),
        getStat(dataA, 'GF'),
        getStat(dataA, 'GA'),
        getStat(dataB, 'Pts'),
        getStat(dataB, 'GD'),
        getStat(dataB, 'GF'),
        getStat(dataB, 'GA'),
      ];

      print("📊 Prediction input: $input");

      // Prepare input and output buffers
      var inputBuffer = Float32List.fromList(input).reshape([1, 8]);
      var outputBuffer = List.filled(3, 0.0).reshape([1, 3]);

      _interpreter.run(inputBuffer, outputBuffer);

      final List<double> probabilities = List<double>.from(outputBuffer[0]);
      final maxProb = probabilities.reduce((a, b) => a > b ? a : b);
      final _ = probabilities.indexOf(maxProb);final PtsA = input[0];
final GDA = input[1];
final PtsB = input[4];
final GDB = input[5];

final scoreA = (PtsA * 0.7 + GDA * 0.3);
final scoreB = (PtsB * 0.7 + GDB * 0.3);

// Calculate pseudo-confidence as % based on score difference
double confidencePercent = (scoreA - scoreB).abs() / (scoreA + scoreB) * 100;
if (confidencePercent.isNaN || confidencePercent.isInfinite) {
  confidencePercent = 50.0; // fallback in case of 0/0
}

String winner;
String reason;

if (scoreA > scoreB) {
  winner = dataA['name'] ?? 'Team A';
  reason = (PtsA > PtsB && GDA > GDB)
      ? 'more points and better goal difference'
      : (PtsA > PtsB)
          ? 'more points in standings'
          : 'better goal difference';
  return {
    'result': '$winner  are going to Win a game ',
    'confidence': '${confidencePercent.toStringAsFixed(1)}% — $reason',
  };
} else if (scoreB > scoreA) {
  winner = dataB['name'] ?? 'Team B';
  reason = (PtsB > PtsA && GDB > GDA)
      ? 'more points and better goal difference'
      : (PtsB > PtsA)
          ? 'more points in standings'
          : 'better goal difference';
  return {
    'result': '$winner are going to Win a game',
    'confidence': '${confidencePercent.toStringAsFixed(1)}% — $reason',
  };
} else {
  return {
    'result': 'The Teams are going to Draw ',
    'confidence': '50% — equal weighted stats'};
}
  }
}
  