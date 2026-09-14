import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../dashboard/domain/models/guardian_status.dart';
import '../../../dashboard/providers/dashboard_provider.dart';
import '../../domain/models/band_device.dart';
import '../../providers/ble_provider.dart';

class BleConnectionScreen extends ConsumerWidget {
  const BleConnectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final telemetry = ref.watch(bandTelemetryProvider);
    final scanResultsAsync = ref.watch(bleScanResultsProvider);
    final isScanningAsync = ref.watch(isScanningProvider);
    final isScanning = isScanningAsync.valueOrNull ?? false;
    final controllerState = ref.watch(bleControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Wearable Connection')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _StatusCard(telemetry: telemetry),
          const SizedBox(height: 20),

          if (controllerState.hasError)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                '${controllerState.error}',
                style: const TextStyle(color: Color(0xFFD32F2F)),
              ),
            ),

          ElevatedButton.icon(
            onPressed: isScanning
                ? () => ref.read(bleControllerProvider.notifier).stopScan()
                : () => ref.read(bleControllerProvider.notifier).startScan(),
            icon: Icon(isScanning
                ? Icons.stop_circle_outlined
                : Icons.bluetooth_searching_rounded),
            label: Text(isScanning ? 'Stop scanning' : 'Scan for band'),
          ),

          const SizedBox(height: 8),
          Text(
            'Note: BLE scanning needs a real phone with Bluetooth — '
            'emulators have no Bluetooth radio and will show no devices.',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: Colors.black45),
          ),

          const SizedBox(height: 20),
          scanResultsAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (err, _) => Text('Scan error: $err'),
            data: (devices) {
              if (devices.isEmpty) {
                return isScanning
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : const SizedBox.shrink();
              }
              return Column(
                children: devices
                    .map((d) => _DeviceTile(device: d))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final BandTelemetry telemetry;
  const _StatusCard({required this.telemetry});

  String get _statusLabel => switch (telemetry.connectionState) {
        BandConnectionState.connected => 'Connected',
        BandConnectionState.connecting => 'Connecting…',
        BandConnectionState.scanning => 'Scanning…',
        BandConnectionState.disconnected => 'Not connected',
      };

  Color get _statusColor => switch (telemetry.connectionState) {
        BandConnectionState.connected => const Color(0xFF1E8E5A),
        BandConnectionState.connecting => const Color(0xFFC98A00),
        BandConnectionState.scanning => const Color(0xFFC98A00),
        BandConnectionState.disconnected => Colors.black45,
      };

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: _statusColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.watch_outlined, color: _statusColor, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_statusLabel,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(color: _statusColor)),
                  if (telemetry.deviceName != null)
                    Text(telemetry.deviceName!,
                        style: Theme.of(context).textTheme.bodyMedium),
                  if (telemetry.batteryPercent != null)
                    Text('Battery ${telemetry.batteryPercent!.round()}%',
                        style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeviceTile extends ConsumerWidget {
  final BandDevice device;
  const _DeviceTile({required this.device});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(Icons.watch_outlined),
        title: Text(device.name.isNotEmpty ? device.name : 'Unnamed device'),
        subtitle: Text('Signal: ${device.rssi} dBm'),
        trailing: ElevatedButton(
          onPressed: () =>
              ref.read(bleControllerProvider.notifier).connect(device),
          child: const Text('Connect'),
        ),
      ),
    );
  }
}