import 'package:flutter/material.dart';

/// Guardian Band hardware and telemetry status screen.
/// Strictly honest: No fake battery levels or fake BLE connection states.
class WearableScreen extends StatelessWidget {
  const WearableScreen({super.key});

  void _showScanDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Pair Guardian Band'),
        content: const Text(
          'Bluetooth Low Energy (BLE) scanning for the ESP32-C3 Guardian Band will be integrated in Phase 3.\n\nMake sure the wearable band is powered on and within 5 meters when pairing begins.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Guardian Band'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          // DEVICE BANNER
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE7E9EC)),
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1F3A5F).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.watch_outlined, color: Color(0xFF1F3A5F), size: 30),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Guardian Band',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Wrist-worn safety sensor',
                        style: TextStyle(fontSize: 13, color: Colors.black54),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF4DE),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Not connected',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFC98A00),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // HONEST TELEMETRY STATUS LIST
          Text(
            'Hardware telemetry',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 10),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(18),
              child: Column(
                children: [
                  _TelemetryRow(
                    icon: Icons.bluetooth_disabled_rounded,
                    label: 'BLE connection',
                    value: 'Not connected',
                    valueColor: Color(0xFFC98A00),
                  ),
                  Divider(height: 24),
                  const _TelemetryRow(
                    icon: Icons.battery_unknown_rounded,
                    label: 'Band battery',
                    value: 'Unavailable',
                    valueColor: Colors.black54,
                  ),
                  Divider(height: 24),
                  const _TelemetryRow(
                    icon: Icons.sos_rounded,
                    label: 'Physical SOS button',
                    value: 'Hardware standby',
                    valueColor: Colors.black87,
                  ),
                  Divider(height: 24),
                  const _TelemetryRow(
                    icon: Icons.sensors_rounded,
                    label: 'Movement sensing (MPU6050)',
                    value: 'Not connected',
                    valueColor: Colors.black54,
                  ),
                  Divider(height: 24),
                  const _TelemetryRow(
                    icon: Icons.vibration_rounded,
                    label: 'Haptic confirmation motor',
                    value: 'Standby',
                    valueColor: Colors.black87,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // NOTICE CARD
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF0EFF9),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF5D5B8D).withValues(alpha: 0.2)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded, color: Color(0xFF5D5B8D), size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'The wearable band communicates directly with the patient\'s smartphone via Bluetooth Low Energy (BLE). Once connected, movement events and SOS button presses are monitored continuously.',
                    style: TextStyle(
                      color: Color(0xFF3C3A68),
                      fontSize: 13,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // PAIR BUTTON
          ElevatedButton.icon(
            onPressed: () => _showScanDialog(context),
            icon: const Icon(Icons.bluetooth_searching_rounded),
            label: const Text('Scan for Guardian Band'),
          ),
        ],
      ),
    );
  }
}

class _TelemetryRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color valueColor;

  const _TelemetryRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF1F3A5F)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label, style: const TextStyle(fontSize: 14, color: Colors.black87)),
        ),
        Text(
          value,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: valueColor),
        ),
      ],
    );
  }
}
