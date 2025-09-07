// lib/models/pod_status.dart

// NEW: Added all the new emotional states we will use.
enum PodEmotionalState {
  sleeping,
  waking,
  happy,
  thirsty,      // Main water tank is empty
  hot,
  thirstySoil,  // Soil is dry, needs watering
  needsNutrients,
  hidingFromLight,
  sunbathing,
  disconnected,
}

// MODIFIED: The class now holds all the data from the Pod's /status JSON.
class PodStatus {
  final String waterLevel;
  final String nutrientLevel;
  final double temperature;
  final int moisture;
  final String ledStatus;
  final int coverAngle1;
  final int coverAngle2;
  final int coverAngle3;

  PodStatus({
    this.waterLevel = 'OK',
    this.nutrientLevel = 'OK',
    this.temperature = 25.0,
    this.moisture = 500,
    this.ledStatus = 'ON',
    this.coverAngle1 = 60,
    this.coverAngle2 = 60,
    this.coverAngle3 = 60,
  });

  // MODIFIED: The factory now parses all the fields from the JSON.
  factory PodStatus.fromJson(Map<String, dynamic> json) {
    return PodStatus(
      waterLevel: json['water_level'] ?? 'OK',
      nutrientLevel: json['nutrient_level'] ?? 'OK',
      temperature: (json['temperature'] as num?)?.toDouble() ?? 25.0,
      moisture: (json['moisture'] as num?)?.toInt() ?? 500,
      ledStatus: json['led_status'] ?? 'ON',
      coverAngle1: (json['cover_angle1'] as num?)?.toInt() ?? 60,
      coverAngle2: (json['cover_angle2'] as num?)?.toInt() ?? 60,
      coverAngle3: (json['cover_angle3'] as num?)?.toInt() ?? 60,
    );
  }
}