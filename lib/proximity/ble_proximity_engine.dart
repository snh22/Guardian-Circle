class BleProximityEngine {
  // ------------------------------------------------------------
  // RSSI proximity processing
  // ------------------------------------------------------------
  //
  // IMPORTANT:
  // RSSI is used only as a proximity signal.
  // We do NOT convert RSSI into an exact distance.
  //
  // These are provisional starting thresholds based on the
  // current physical calibration:
  //
  // CLOSE: RSSI >= -74 dBm
  // NEAR:  -84 dBm < RSSI < -74 dBm
  // FAR:   RSSI <= -84 dBm
  //
  // These thresholds must be physically validated after
  // smoothing is integrated with the real BLE scanner.

  static const int windowSize = 7;
  static const int confirmationSamples = 3;

  static const double closeThreshold = -74.0;
  static const double farThreshold = -84.0;

  // Hysteresis prevents rapid switching around thresholds.
  //
  // Example:
  // FAR -> NEAR requires RSSI to become stronger than -80 dBm.
  // NEAR -> FAR requires RSSI to become weaker than -84 dBm.
  //
  // CLOSE uses the same principle around -74 dBm.
  static const double hysteresis = 2.0;

  final List<double> _rssiWindow = [];

  double? _rawRssi;
  double? _smoothedRssi;

  String _state = 'unknown';

  int _closeConfirmationCount = 0;
  int _nearConfirmationCount = 0;
  int _farConfirmationCount = 0;

  // ------------------------------------------------------------
  // Public getters
  // ------------------------------------------------------------

  int get sampleCount => _rssiWindow.length;

  List<double> get rssiSamples =>
      List.unmodifiable(_rssiWindow);

  double? get rawRssi => _rawRssi;

  double? get smoothedRssi => _smoothedRssi;

  String get state => _state;

  // Human-readable label for UI.
  String get proximityLabel {
    switch (_state) {
      case 'close':
        return 'Within ~5 m';
      case 'near':
        return '~5–10 m';
      case 'far':
        return 'Beyond ~10 m';
      case 'signal_lost':
        return 'Patient Signal Lost';
      default:
        return 'Waiting for patient signal';
    }
  }

  // ------------------------------------------------------------
  // RSSI processing
  // ------------------------------------------------------------

  void addRssi(int rssi) {
    _rawRssi = rssi.toDouble();

    _rssiWindow.add(_rawRssi!);

    if (_rssiWindow.length > windowSize) {
      _rssiWindow.removeAt(0);
    }

    _smoothedRssi = _calculateAverage();

    _updateState(_smoothedRssi!);
  }

  // ------------------------------------------------------------
  // Rolling average
  // ------------------------------------------------------------

  double _calculateAverage() {
    if (_rssiWindow.isEmpty) {
      return 0;
    }

    final total =
        _rssiWindow.reduce((a, b) => a + b);

    return total / _rssiWindow.length;
  }

  // ------------------------------------------------------------
  // Stable proximity state
  // ------------------------------------------------------------

  void _updateState(double rssi) {
    final candidate = _candidateState(rssi);

    switch (candidate) {
      case 'close':
        _closeConfirmationCount++;
        _nearConfirmationCount = 0;
        _farConfirmationCount = 0;

        if (_closeConfirmationCount >= confirmationSamples) {
          _state = 'close';
        }
        break;

      case 'near':
        _nearConfirmationCount++;
        _closeConfirmationCount = 0;
        _farConfirmationCount = 0;

        if (_nearConfirmationCount >= confirmationSamples) {
          _state = 'near';
        }
        break;

      case 'far':
        _farConfirmationCount++;
        _closeConfirmationCount = 0;
        _nearConfirmationCount = 0;

        if (_farConfirmationCount >= confirmationSamples) {
          _state = 'far';
        }
        break;
    }
  }

  // ------------------------------------------------------------
  // Hysteresis-aware candidate state
  // ------------------------------------------------------------

  String _candidateState(double rssi) {
    switch (_state) {
      case 'close':
        // Once CLOSE, do not leave it until signal becomes
        // meaningfully weaker than the normal CLOSE boundary.
        if (rssi >= closeThreshold - hysteresis) {
          return 'close';
        }

        if (rssi <= farThreshold) {
          return 'far';
        }

        return 'near';

      case 'far':
        // Once FAR, do not leave it until signal becomes
        // meaningfully stronger than the normal FAR boundary.
        if (rssi <= farThreshold + hysteresis) {
          return 'far';
        }

        if (rssi >= closeThreshold) {
          return 'close';
        }

        return 'near';

      case 'near':
      case 'unknown':
      default:
        if (rssi >= closeThreshold) {
          return 'close';
        }

        if (rssi <= farThreshold) {
          return 'far';
        }

        return 'near';
    }
  }

  // ------------------------------------------------------------
  // Signal loss
  // ------------------------------------------------------------
  //
  // The scanner/provider will decide when the patient
  // advertisement has not been received for the configured
  // timeout.
  //
  // This method does NOT start another scanner or timer.
  // That keeps signal-loss handling separate from the
  // existing BLE scanning implementation.

  void markSignalLost() {
    _state = 'signal_lost';

    _closeConfirmationCount = 0;
    _nearConfirmationCount = 0;
    _farConfirmationCount = 0;
  }

  // ------------------------------------------------------------
  // Reset
  // ------------------------------------------------------------

  void reset() {
    _rssiWindow.clear();

    _rawRssi = null;
    _smoothedRssi = null;

    _state = 'unknown';

    _closeConfirmationCount = 0;
    _nearConfirmationCount = 0;
    _farConfirmationCount = 0;
  }
}
