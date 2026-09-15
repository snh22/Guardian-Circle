import 'dart:async';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../dashboard/domain/models/guardian_status.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../domain/models/band_device.dart';

// Standard Bluetooth GATT Battery Service / Characteristic UUIDs —
// use these if the real Guardian Band firmware exposes standard BLE
// battery reporting. If the band's firmware uses a custom characteristic
// instead, swap these UUIDs for the ones in its BLE profile doc.
final _batteryServiceUuid = Guid('0000180f-0000-1000-8000-00805f9b34fb');
final _batteryCharUuid = Guid('00002a19-0000-1000-8000-00805f9b34fb');

/// NOTE: BLE scanning needs a REAL phone/device with Bluetooth hardware.
/// Android emulators have no Bluetooth radio, so scans will always come
/// back empty there — this is expected, not a bug. Test on a physical
/// Android device once you have a real Guardian Band to pair with.

Future<bool> requestBlePermissions() async {
  final statuses = await [
    Permission.bluetoothScan,
    Permission.bluetoothConnect,
    Permission.locationWhenInUse,
  ].request();
  return statuses.values.every((s) => s.isGranted);
}

/// Live scan results as they come in.
final bleScanResultsProvider =
    StreamProvider.autoDispose<List<BandDevice>>((ref) {
  return FlutterBluePlus.scanResults.map(
    (results) => results.map(BandDevice.fromScanResult).toList(),
  );
});

final isScanningProvider = StreamProvider.autoDispose<bool>((ref) {
  return FlutterBluePlus.isScanning;
});

class BleController extends StateNotifier<AsyncValue<void>> {
  BleController(this._ref) : super(const AsyncValue.data(null));

  final Ref _ref;
  StreamSubscription<BluetoothConnectionState>? _connectionSub;

  Future<void> startScan() async {
    final granted = await requestBlePermissions();
    if (!granted) {
      state = AsyncValue.error(
        'Bluetooth/location permission was not granted.',
        StackTrace.current,
      );
      return;
    }
    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));
  }

  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
  }

  Future<void> connect(BandDevice device) async {
    state = const AsyncValue.loading();
    _ref.read(bandTelemetryProvider.notifier).state = BandTelemetry(
      connectionState: BandConnectionState.connecting,
      deviceName: device.name,
    );

    try {
      await stopScan();
      await device.rawDevice.connect(timeout: const Duration(seconds: 10));

      _connectionSub?.cancel();
      _connectionSub = device.rawDevice.connectionState.listen((connState) {
        if (connState == BluetoothConnectionState.disconnected) {
          _ref.read(bandTelemetryProvider.notifier).state =
              const BandTelemetry(
            connectionState: BandConnectionState.disconnected,
          );
        }
      });

      final battery = await _readBattery(device.rawDevice);

      _ref.read(bandTelemetryProvider.notifier).state = BandTelemetry(
        connectionState: BandConnectionState.connected,
        deviceName: device.name,
        batteryPercent: battery,
        lastSeen: DateTime.now(),
      );
      state = const AsyncValue.data(null);
    } catch (e, st) {
      _ref.read(bandTelemetryProvider.notifier).state = const BandTelemetry(
        connectionState: BandConnectionState.disconnected,
      );
      state = AsyncValue.error(e, st);
    }
  }

  Future<double?> _readBattery(BluetoothDevice device) async {
    try {
      final services = await device.discoverServices();
      final batteryService = services.firstWhere(
        (s) => s.uuid == _batteryServiceUuid,
      );
      final batteryChar = batteryService.characteristics.firstWhere(
        (c) => c.uuid == _batteryCharUuid,
      );
      final value = await batteryChar.read();
      if (value.isNotEmpty) return value.first.toDouble();
      return null;
    } catch (_) {
      // Band doesn't expose standard battery service, or read failed —
      // not fatal, just means battery % won't show yet.
      return null;
    }
  }

  Future<void> disconnect(BandDevice device) async {
    await device.rawDevice.disconnect();
    _ref.read(bandTelemetryProvider.notifier).state = const BandTelemetry(
      connectionState: BandConnectionState.disconnected,
    );
  }

  @override
  void dispose() {
    _connectionSub?.cancel();
    super.dispose();
  }
}

final bleControllerProvider =
    StateNotifierProvider.autoDispose<BleController, AsyncValue<void>>(
  (ref) => BleController(ref),
);