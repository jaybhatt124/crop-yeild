import '../utils/app_constants.dart';

/// Prediction result model returned by the prediction service.
class PredictionResult {
  final double yieldValue;
  final String unit;
  final int confidencePercent;
  final String suggestedCrop;
  final String waterTip;
  final String fertilizerTip;
  final String generalTip;
  final String cropType;

  const PredictionResult({
    required this.yieldValue,
    required this.unit,
    required this.confidencePercent,
    required this.suggestedCrop,
    required this.waterTip,
    required this.fertilizerTip,
    required this.generalTip,
    required this.cropType,
  });
}

/// Simulates a backend ML API call for crop yield prediction.
/// In production, replace this with an actual HTTP request to your ML API.
class PredictionService {

  /// Fetches a yield prediction based on input parameters.
  /// Simulates network delay and returns a dummy result.
  Future<PredictionResult> predictYield({
    required String cropType,
    required String soilType,
    required String location,
    required double rainfall,
    required double temperature,
    required double humidity,
  }) async {
    // ── Simulate network/ML processing delay ──
    await Future.delayed(const Duration(seconds: 2));

    // ── In production: make HTTP POST to ML API ──
    // final response = await http.post(
    //   Uri.parse('https://your-api.com/predict'),
    //   headers: {'Content-Type': 'application/json'},
    //   body: jsonEncode({
    //     'crop_type': cropType,
    //     'soil_type': soilType,
    //     'location': location,
    //     'rainfall': rainfall,
    //     'temperature': temperature,
    //     'humidity': humidity,
    //   }),
    // );
    // final data = jsonDecode(response.body);

    // ── Look up dummy prediction data ──
    final predData = AppConstants.dummyPredictions[cropType]
        ?? AppConstants.defaultPrediction;

    // ── Apply minor variation based on inputs for realism ──
    double baseYield = (predData['yield'] as num).toDouble();
    double adjustedYield = _applyInputVariation(
      baseYield,
      rainfall: rainfall,
      temperature: temperature,
      humidity: humidity,
    );

    return PredictionResult(
      yieldValue: double.parse(adjustedYield.toStringAsFixed(2)),
      unit: predData['unit'] as String,
      confidencePercent: predData['confidence'] as int,
      suggestedCrop: predData['suggested'] as String,
      waterTip: predData['waterTip'] as String,
      fertilizerTip: predData['fertilizerTip'] as String,
      generalTip: predData['generalTip'] as String,
      cropType: cropType,
    );
  }

  /// Applies a small ±10% variation to the base yield based on environmental inputs.
  double _applyInputVariation(
    double baseYield, {
    required double rainfall,
    required double temperature,
    required double humidity,
  }) {
    double factor = 1.0;

    // Rainfall factor (optimal: 500-1000mm)
    if (rainfall >= 500 && rainfall <= 1000) {
      factor += 0.05;
    } else if (rainfall < 300 || rainfall > 1500) {
      factor -= 0.08;
    }

    // Temperature factor (optimal: 20-30°C)
    if (temperature >= 20 && temperature <= 30) {
      factor += 0.03;
    } else if (temperature < 10 || temperature > 40) {
      factor -= 0.07;
    }

    // Humidity factor (optimal: 50-75%)
    if (humidity >= 50 && humidity <= 75) {
      factor += 0.02;
    } else if (humidity < 30 || humidity > 90) {
      factor -= 0.05;
    }

    return baseYield * factor.clamp(0.8, 1.1);
  }
}
