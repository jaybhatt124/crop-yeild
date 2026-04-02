import 'package:cloud_firestore/cloud_firestore.dart';

/// Model representing a single crop data entry submitted by the farmer.
class CropInput {
  final String? id;
  final String userId;
  final String location;
  final String soilType;
  final String cropType;
  final double rainfall;      // mm
  final double temperature;   // °C
  final double humidity;      // %
  final DateTime timestamp;
  final double? predictedYield;
  final String? suggestedCrop;

  const CropInput({
    this.id,
    required this.userId,
    required this.location,
    required this.soilType,
    required this.cropType,
    required this.rainfall,
    required this.temperature,
    required this.humidity,
    required this.timestamp,
    this.predictedYield,
    this.suggestedCrop,
  });

  // ─── Firestore Serialization ─────────────────────────────────────────

  /// Convert model to Firestore-compatible map.
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'location': location,
      'soilType': soilType,
      'cropType': cropType,
      'rainfall': rainfall,
      'temperature': temperature,
      'humidity': humidity,
      'timestamp': Timestamp.fromDate(timestamp),
      'predictedYield': predictedYield,
      'suggestedCrop': suggestedCrop,
    };
  }

  /// Create model from Firestore DocumentSnapshot.
  factory CropInput.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CropInput(
      id: doc.id,
      userId: data['userId'] ?? '',
      location: data['location'] ?? '',
      soilType: data['soilType'] ?? '',
      cropType: data['cropType'] ?? '',
      rainfall: (data['rainfall'] as num?)?.toDouble() ?? 0.0,
      temperature: (data['temperature'] as num?)?.toDouble() ?? 0.0,
      humidity: (data['humidity'] as num?)?.toDouble() ?? 0.0,
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      predictedYield: (data['predictedYield'] as num?)?.toDouble(),
      suggestedCrop: data['suggestedCrop'],
    );
  }

  /// Create a copy with optional updated fields.
  CropInput copyWith({
    String? id,
    String? userId,
    String? location,
    String? soilType,
    String? cropType,
    double? rainfall,
    double? temperature,
    double? humidity,
    DateTime? timestamp,
    double? predictedYield,
    String? suggestedCrop,
  }) {
    return CropInput(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      location: location ?? this.location,
      soilType: soilType ?? this.soilType,
      cropType: cropType ?? this.cropType,
      rainfall: rainfall ?? this.rainfall,
      temperature: temperature ?? this.temperature,
      humidity: humidity ?? this.humidity,
      timestamp: timestamp ?? this.timestamp,
      predictedYield: predictedYield ?? this.predictedYield,
      suggestedCrop: suggestedCrop ?? this.suggestedCrop,
    );
  }
}
