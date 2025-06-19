import 'dart:convert';
import 'package:flutter/material.dart';

enum AlertSeverity { low, moderate, high, extreme }

class WeatherAlert {
  final String id;
  final String city;
  final String alertType;
  final String description;
  final DateTime timestamp;
  final AlertSeverity severity;
  final String? additionalInfo;

  WeatherAlert({
    required this.id,
    required this.city,
    required this.alertType,
    required this.description,
    required this.timestamp,
    required this.severity,
    this.additionalInfo,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'city': city,
      'alertType': alertType,
      'description': description,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'severity': severity.index,
      'additionalInfo': additionalInfo,
    };
  }

  factory WeatherAlert.fromMap(Map<String, dynamic> map) {
    return WeatherAlert(
      id: map['id'] ?? '',
      city: map['city'] ?? '',
      alertType: map['alertType'] ?? '',
      description: map['description'] ?? '',
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
      severity: AlertSeverity.values[map['severity'] ?? 0],
      additionalInfo: map['additionalInfo'],
    );
  }

  String toJson() => json.encode(toMap());

  factory WeatherAlert.fromJson(String source) =>
      WeatherAlert.fromMap(json.decode(source));

  String get severityText {
    switch (severity) {
      case AlertSeverity.low:
        return 'Low';
      case AlertSeverity.moderate:
        return 'Moderate';
      case AlertSeverity.high:
        return 'High';
      case AlertSeverity.extreme:
        return 'Extreme';
    }
  }

  String get severityEmoji {
    switch (severity) {
      case AlertSeverity.low:
        return '🟡';
      case AlertSeverity.moderate:
        return '🟠';
      case AlertSeverity.high:
        return '🔴';
      case AlertSeverity.extreme:
        return '🚨';
    }
  }

  Color get severityColor {
    switch (severity) {
      case AlertSeverity.low:
        return const Color(0xFFFFC107); // Amber
      case AlertSeverity.moderate:
        return const Color(0xFFFF9800); // Orange
      case AlertSeverity.high:
        return const Color(0xFFF44336); // Red
      case AlertSeverity.extreme:
        return const Color(0xFF9C27B0); // Purple
    }
  }
}
