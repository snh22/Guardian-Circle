import 'dart:math';

class BleProximityEngine {
  // ------------------------------------------------------------
  // Calibration points from the OPPO A18 testing
  // ------------------------------------------------------------
  //
  // RSSI values are represented as negative dBm internally.
  //
  // Approximate measurements:
  // 1 m  -> -47.4 dBm
  // 2 m  -> -56.0 dBm
  // 3 m  -> -59.4 dBm
  // 5 m  -> -61.8 dBm
  // 10 m -> -65.8 dBm
  //
  // RSSI is noisy, so we never use a single reading.

  static const List<_CalibrationPoint> _calibrationPoints = [
    _CalibrationPoint(1.0, -47.4),
    _CalibrationPoint(2.0, -56.0),
    _CalibrationPoint(3.0, -59.4),
    _CalibrationPoint(5.0, -61.8),
    _CalibrationPoint(10.0, -65.8),
  ];

  // ------------------------------------------------------------
  // Configurable Guardian Circle
  // ------------------------------------------------------------

  double _boundaryDistance = 10.0;

  double _boundaryRssi = -65.8;

  double _insideThreshold = -64.0;

  double _outsideThreshold = -67.5;

  // ------------------------------------------------------------
  // Filtering
  // ------------------------------------------------------------

  static const int windowSize = 15;

  final List<double> _rssiWindow = [];

  // ------------------------------------------------------------
  // State
  // ------------------------------------------------------------

  String state = 'inside';

  int _outsideConfirmationCount = 0;
  int _insideConfirmationCount = 0;

  static const int confirmationSamples = 5;

  // ------------------------------------------------------------
  // Public getters
  // ------------------------------------------------------------

  double get boundaryDistance => _boundaryDistance;

  double get boundaryRssi => _boundaryRssi;

  double get insideThreshold => _insideThreshold;

  double get outsideThreshold => _outsideThreshold;

  List<double> get rssiSamples =>
      List.unmodifiable(_rssiWindow);

  int get sampleCount => _rssiWindow.length;

  // ------------------------------------------------------------
  // Change Guardian Circle radius
  // ------------------------------------------------------------

  void setBoundaryDistance(double distance) {
    if (distance <= 0) {
      return;
    }

    _boundaryDistance = distance;

    _recalculateThresholds();

    // Re-evaluate from the current filtered value.
    if (_rssiWindow.isNotEmpty) {
      _updateState(_filteredRssi);
    }
  }

  // ------------------------------------------------------------
  // RSSI processing
  // ------------------------------------------------------------

  void addRssi(int rssi) {
    final value = rssi.toDouble();

    _rssiWindow.add(value);

    if (_rssiWindow.length > windowSize) {
      _rssiWindow.removeAt(0);
    }

    if (_rssiWindow.length < windowSize) {
      state = 'boundary';
      return;
    }

    _updateState(_filteredRssi);
  }

  // ------------------------------------------------------------
  // Filtered RSSI
  // ------------------------------------------------------------

  double get _filteredRssi {
    if (_rssiWindow.isEmpty) {
      return 0;
    }

    final sorted = List<double>.from(_rssiWindow)
      ..sort();

    // Trim the weakest and strongest readings.
    final trimmed = sorted.sublist(2, sorted.length - 2);

    return trimmed.reduce((a, b) => a + b) /
        trimmed.length;
  }

  double get filteredRssi => _filteredRssi;

  // ------------------------------------------------------------
  // Signal confidence
  // ------------------------------------------------------------

  double get confidence {
    if (_rssiWindow.length < windowSize) {
      return 0;
    }

    final mean = _filteredRssi;

    double variance = 0;

    for (final value in _rssiWindow) {
      final difference = value - mean;
      variance += difference * difference;
    }

    variance /= _rssiWindow.length;

    final standardDeviation = sqrt(variance);

    if (standardDeviation <= 2.0) {
      return 95;
    }

    if (standardDeviation <= 4.0) {
      return 80;
    }

    if (standardDeviation <= 6.0) {
      return 60;
    }

    if (standardDeviation <= 9.0) {
      return 40;
    }

    return 20;
  }

  // ------------------------------------------------------------
  // State machine
  // ------------------------------------------------------------

  void _updateState(double rssi) {
    // Strong signal = definitely inside.
    if (rssi >= _insideThreshold) {
      _insideConfirmationCount++;

      _outsideConfirmationCount = 0;

      if (_insideConfirmationCount >=
          confirmationSamples) {
        state = 'inside';
      }

      return;
    }

    // Weak signal = possible outside.
    if (rssi <= _outsideThreshold) {
      _outsideConfirmationCount++;

      _insideConfirmationCount = 0;

      if (_outsideConfirmationCount >=
          confirmationSamples) {
        state = 'outside';
      }

      return;
    }

    // Between the two thresholds = boundary.
    _outsideConfirmationCount = 0;
    _insideConfirmationCount = 0;

    state = 'boundary';
  }

  // ------------------------------------------------------------
  // Threshold calculation
  // ------------------------------------------------------------

  void _recalculateThresholds() {
    _boundaryRssi =
        _estimateRssiForDistance(_boundaryDistance);

    // Hysteresis:
    //
    // insideThreshold is slightly stronger than the
    // boundary value.
    //
    // outsideThreshold is slightly weaker than the
    // boundary value.
    //
    // This prevents rapid INSIDE <-> OUTSIDE switching
    // when RSSI fluctuates around the boundary.

    _insideThreshold = _boundaryRssi + 2.0;

    _outsideThreshold = _boundaryRssi - 2.0;
  }

  // ------------------------------------------------------------
  // Estimate RSSI for requested distance
  // ------------------------------------------------------------

  double _estimateRssiForDistance(double distance) {
    // Below first calibration point.
    if (distance <= _calibrationPoints.first.distance) {
      return _calibrationPoints.first.rssi;
    }

    // Above last calibration point.
    if (distance >= _calibrationPoints.last.distance) {
      return _calibrationPoints.last.rssi;
    }

    // Find the two calibration points surrounding
    // the requested distance.
    for (int i = 0;
        i < _calibrationPoints.length - 1;
        i++) {
      final lower = _calibrationPoints[i];
      final upper = _calibrationPoints[i + 1];

      if (distance >= lower.distance &&
          distance <= upper.distance) {
        final distanceDifference =
            upper.distance - lower.distance;

        final position =
            (distance - lower.distance) /
                distanceDifference;

        return lower.rssi +
            (upper.rssi - lower.rssi) * position;
      }
    }

    return _calibrationPoints.last.rssi;
  }

  // ------------------------------------------------------------
  // Reset
  // ------------------------------------------------------------

  void reset() {
    _rssiWindow.clear();

    state = 'inside';

    _outsideConfirmationCount = 0;
    _insideConfirmationCount = 0;
  }
}

// ------------------------------------------------------------
// Calibration point
// ------------------------------------------------------------

class _CalibrationPoint {
  final double distance;
  final double rssi;

  const _CalibrationPoint(
    this.distance,
    this.rssi,
  );
}