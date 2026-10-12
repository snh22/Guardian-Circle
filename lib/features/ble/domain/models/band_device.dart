import 'package:flutter_blue_plus/flutter_blue_plus.dart';

/// Wraps a flutter_blue_plus ScanResult with just what the UI needs,
/// so screens/widgets don't depend on the plugin's types directly.
class BandDevice {
  static const int guardianManufacturerId = 0x1234;
  static const String guardianPatientName = 'GUARDIAN_PATIENT';
  static final Guid guardianServiceUuid =
      Guid('0000fc00-0000-1000-8000-00805f9b34fb');

  final String id;
  final String name;
  final int rssi;
  final BluetoothDevice rawDevice;
  final Map<int, List<int>> manufacturerData;
  final List<Guid> serviceUuids;

  const BandDevice({
    required this.id,
    required this.name,
    required this.rssi,
    required this.rawDevice,
    required this.manufacturerData,
    required this.serviceUuids,
  });

  factory BandDevice.fromScanResult(ScanResult result) {
    final advertisement = result.advertisementData;

    return BandDevice(
      id: result.device.remoteId.str,
      name: result.device.platformName.isNotEmpty
          ? result.device.platformName
          : advertisement.advName,
      rssi: result.rssi,
      rawDevice: result.device,
      manufacturerData: Map.unmodifiable(advertisement.manufacturerData),
      serviceUuids: List.unmodifiable(advertisement.serviceUuids),
    );
  }

  bool get isGuardianPatient {
    final normalizedName = name.trim().toUpperCase();

    final hasPatientName = normalizedName == guardianPatientName;
    final hasGuardianName = normalizedName.contains('GUARDIAN');
    final hasManufacturer = manufacturerData.containsKey(
      guardianManufacturerId,
    );
    final hasService = serviceUuids.any(
      (uuid) => uuid == guardianServiceUuid,
    );

    return hasPatientName ||
        (hasManufacturer && hasService) ||
        (hasGuardianName && hasService);
  }
}
