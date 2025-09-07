import 'package:flutter/material.dart';
import '../models/pod_status.dart';

class DataOverlay extends StatelessWidget {
  final PodStatus status;

  const DataOverlay({Key? key, required this.status}) : super(key: key);

  // Helper to create a consistent text style
  TextStyle _textStyle(double size, {bool isLabel = false}) {
    return TextStyle(
      fontFamily: 'monospace', // Gives it a "techy" feel
      fontSize: size,
      color: isLabel ? Colors.cyan.withOpacity(0.6) : Colors.cyan,
      shadows: [
        Shadow(
          blurRadius: isLabel ? 4.0 : 8.0,
          color: Colors.cyan.withOpacity(0.5),
        ),
      ],
    );
  }

  // Helper to format a single data row
  Widget _buildDataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('$label:', style: _textStyle(14, isLabel: true)),
          Text(value, style: _textStyle(16)),
        ],
      ),
    );
  }

  // Helper to convert raw moisture value to a percentage
  String _formatMoisture(int moisture) {
    // Assuming a common sensor range of 0 (wet) to ~1023 (dry)
    // We'll invert it so high % is more moist.
    if (moisture > 1023) moisture = 1023;
    final percentage = 100 - (moisture / 1023 * 100);
    return '${percentage.toStringAsFixed(0)}%';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.65),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.cyan.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.cyan.withOpacity(0.2),
            blurRadius: 12.0,
            spreadRadius: 2.0,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '// POD STATUS //',
            style: _textStyle(18, isLabel: true),
          ),
          const SizedBox(height: 12),
          _buildDataRow('INTERNAL TEMP', '${status.temperature.toStringAsFixed(1)}°C'),
          // NOTE: Ambient Humidity is not in the PodStatus model.
          // Using moisture as a placeholder.
          _buildDataRow('SOIL MOISTURE', _formatMoisture(status.moisture)),
          _buildDataRow('LIGHT LEVELS', status.ledStatus),
          _buildDataRow('WATER RESERVOIR', status.waterLevel),
          _buildDataRow('NUTRIENT SUPPLY', status.nutrientLevel),
        ],
      ),
    );
  }
}