class AppConstants {
  // ─── Firestore Collections ──────────────────────────────────────────
  static const String cropInputsCollection = 'crop_inputs';
  static const String usersCollection = 'users';

  // ─── Crop Types ──────────────────────────────────────────────────────
  static const List<String> cropTypes = [
    'Rice',
    'Wheat',
    'Maize (Corn)',
    'Sugarcane',
    'Cotton',
    'Soybean',
    'Groundnut',
    'Sunflower',
    'Barley',
    'Millet',
    'Sorghum',
    'Potato',
    'Tomato',
    'Onion',
    'Mustard',
  ];

  // ─── Soil Types ──────────────────────────────────────────────────────
  static const List<String> soilTypes = [
    'Alluvial Soil',
    'Black Soil (Regur)',
    'Red Soil',
    'Laterite Soil',
    'Arid / Desert Soil',
    'Forest Soil',
    'Saline Soil',
    'Peaty Soil',
    'Clay Soil',
    'Sandy Loam',
  ];

  // ─── Locations (Indian States) ───────────────────────────────────────
  static const List<String> locations = [
    'Andhra Pradesh',
    'Bihar',
    'Chhattisgarh',
    'Gujarat',
    'Haryana',
    'Karnataka',
    'Kerala',
    'Madhya Pradesh',
    'Maharashtra',
    'Odisha',
    'Punjab',
    'Rajasthan',
    'Tamil Nadu',
    'Telangana',
    'Uttar Pradesh',
    'West Bengal',
    'Assam',
    'Himachal Pradesh',
    'Uttarakhand',
    'Jammu & Kashmir',
  ];

  // ─── Dummy Prediction Map ────────────────────────────────────────────
  // Format: 'cropType': { yield_tons_per_hectare, suggested_crop, tips }
  static const Map<String, Map<String, dynamic>> dummyPredictions = {
    'Rice': {
      'yield': 4.2,
      'unit': 'tons/hectare',
      'confidence': 87,
      'suggested': 'Rice (IR-64 Variety)',
      'waterTip': 'Maintain 5cm flood water during tillering. Irrigate every 2-3 days.',
      'fertilizerTip': 'Apply 120 kg/ha NPK (40:20:20). Split urea in 3 doses.',
      'generalTip': 'Transplant at 25-30 days seedling age for best results.',
    },
    'Wheat': {
      'yield': 3.8,
      'unit': 'tons/hectare',
      'confidence': 91,
      'suggested': 'Wheat (HD-2967)',
      'waterTip': 'Irrigate at Crown Root Initiation (21 days) and heading stage.',
      'fertilizerTip': 'Apply 150:60:40 kg/ha NPK. Apply half N at sowing.',
      'generalTip': 'Sow in first fortnight of November for optimal yield.',
    },
    'Maize (Corn)': {
      'yield': 5.5,
      'unit': 'tons/hectare',
      'confidence': 84,
      'suggested': 'Maize (Pioneer 30V92)',
      'waterTip': 'Critical irrigation at knee-high, tasseling, and silking stages.',
      'fertilizerTip': 'Apply 180:60:40 kg/ha NPK. Top dress with urea at 30 days.',
      'generalTip': 'Maintain plant population of 65,000-75,000/hectare.',
    },
    'Sugarcane': {
      'yield': 72.0,
      'unit': 'tons/hectare',
      'confidence': 79,
      'suggested': 'Sugarcane (Co 0238)',
      'waterTip': 'Irrigate at 7-10 day intervals during formative phase.',
      'fertilizerTip': 'Apply 250:100:120 kg/ha NPK. Earthing up with fertilizer.',
      'generalTip': 'Ratoon crop management improves long-term profitability.',
    },
    'Cotton': {
      'yield': 2.1,
      'unit': 'tons/hectare',
      'confidence': 82,
      'suggested': 'Cotton (Bt-Hybrid RCH 650)',
      'waterTip': 'Irrigate at 50% flower opening and boll development stages.',
      'fertilizerTip': 'Apply 120:60:60 kg/ha NPK. Boron and Zinc as micronutrients.',
      'generalTip': 'Maintain optimal plant density of 11,000 plants/hectare.',
    },
  };

  // Default prediction for unlisted crops
  static Map<String, dynamic> get defaultPrediction => {
    'yield': 3.2,
    'unit': 'tons/hectare',
    'confidence': 75,
    'suggested': 'Current selected crop',
    'waterTip': 'Ensure adequate irrigation at critical growth stages.',
    'fertilizerTip': 'Apply balanced NPK fertilizer as per soil test recommendations.',
    'generalTip': 'Regular monitoring and pest management ensures best yield.',
  };
}
