import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../../../proximity/ble_proximity_engine.dart';
import '../domain/models/band_device.dart';
import 'ble_provider.dart';

class BleProximityState {
  final double? rawRssi;
  final double? smoothedRssi;
  final String state;
  final String label;
  final bool signalLost;
  final int sampleCount;
  final String? patientDeviceId;

  const BleProximityState({
    required this.rawRssi,
    required this.smoothedRssi,
    required this.state,
    required this.label,
    required this.signalLost,
    required this.sampleCount,
    required this.patientDeviceId,
  });

  factory BleProximityState.initial() {
    return const BleProximityState(
      rawRssi: null,
      smoothedRssi: null,
      state: 'unknown',
      label: 'Waiting for patient signal',
      signalLost: false,
      sampleCount: 0,
      patientDeviceId: null,
    );
  }

  BleProximityState copyWith({
    double? rawRssi,
    double? smoothedRssi,
    String? state,
    String? label,
    bool? signalLost,
    int? sampleCount,
    String? patientDeviceId,
  }) {
    return BleProximityState(
      rawRssi: rawRssi ?? this.rawRssi,
      smoothedRssi: smoothedRssi ?? this.smoothedRssi,
      state: state ?? this.state,
      label: label ?? this.label,
      signalLost: signalLost ?? this.signalLost,
      sampleCount: sampleCount ?? this.sampleCount,
      patientDeviceId: patientDeviceId ?? this.patientDeviceId,
    );
  }
}

class BleProximityController extends StateNotifier<BleProximityState> {
  BleProximityController(this._ref)
      : _engine = BleProximityEngine(),
        super(BleProximityState.initial()) {
    _scanSubscription = _ref.listen<AsyncValue<List<BandDevice>>>(
      bleScanResultsProvider,
      (_, next) => _handleScanResults(next),
      fireImmediately: true,
    );

    _startPatientScan();
  }

  Future<void> _startPatientScan() async {
    final granted = await requestBlePermissions();

    if (!granted) {
      return;
    }

    try {
      if (FlutterBluePlus.isScanningNow) {
        return;
      }

      await FlutterBluePlus.startScan(
        timeout: const Duration(minutes: 30),
      );
    } catch (_) {
      // Keep the dashboard usable if BLE scanning cannot start.
    }
  }

  final Ref _ref;
  final BleProximityEngine _engine;
  late final ProviderSubscription<AsyncValue<List<BandDevice>>>
      _scanSubscription;

  Timer? _signalTimer;

  static const Duration signalTimeout = Duration(seconds: 5);

  void _handleScanResults(AsyncValue<List<BandDevice>> result) {
    result.whenData((devices) {
      BandDevice? patient;

      for (final device in devices) {
        if (device.isGuardianPatient) {
          patient = device;
          break;
        }
      }

      if (patient == null) {
        return;
      }

      _engine.addRssi(patient.rssi);
      _signalTimer?.cancel();
      _signalTimer = Timer(signalTimeout, _markSignalLost);

      state = BleProximityState(
        rawRssi: _engine.rawRssi,
        smoothedRssi: _engine.smoothedRssi,
        state: _engine.state,
        label: _engine.proximityLabel,
        signalLost: false,
        sampleCount: _engine.sampleCount,
        patientDeviceId: patient.id,
      );
    });
  }

  void _markSignalLost() {
    _engine.markSignalLost();

    state = BleProximityState(
      rawRssi: _engine.rawRssi,
      smoothedRssi: _engine.smoothedRssi,
      state: _engine.state,
      label: _engine.proximityLabel,
      signalLost: true,
      sampleCount: _engine.sampleCount,
      patientDeviceId: state.patientDeviceId,
    );
  }

  @override
  void dispose() {
    _signalTimer?.cancel();
    _scanSubscription.close();
    super.dispose();
  }
}

final bleProximityProvider = StateNotifierProvider.autoDispose<
    BleProximityController, BleProximityState>(
  (ref) => BleProximityController(ref),
);
