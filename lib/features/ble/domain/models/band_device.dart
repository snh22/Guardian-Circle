import 'package:flutter_blue_plus/flutter_blue_plus.dart';

/// Wraps a flutter_blue_plus ScanResult with just what the UI needs,
/// so screens/widgets don't depend on the plugin's types directly.
class BandDevice {
  final String id;
  final String name;
  final int rssi;
  final BluetoothDevice rawDevice;

  const BandDevice({
    required this.id,
    required this.name,
    required this.rssi,
    required this.rawDevice,
  });

  factory BandDevice.fromScanResult(ScanResult result) {
    return BandDevice(
      id: result.device.remoteId.str,
      name: result.device.platformName.isNotEmpty
          ? result.device.platformName
          : result.advertisementData.advName,
      rssi: result.rssi,
      rawDevice: result.device,
    );
  }
}