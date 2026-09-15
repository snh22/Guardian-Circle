import 'dart:math';

enum ProximityState {
  inside,
  boundary,
  outside,
  signalUncertain,
}

class BleProximityResult {
  final ProximityState state;
  final int? rssi;
  final double? filteredRssi;
  final double confidence;
  final int sampleCount;

  const BleProximityResult({
    required this.state,
    required this.rssi,
    required this.filteredRssi,
    required this.confidence,
    required this.sampleCount,
  });
}

class BleProximityEngine {
  // --------------------------------------------------
  // GENERAL SETTINGS
  // --------------------------------------------------

  static const int windowSize = 15;

  // How many consecutive samples are required
  // before changing to another confirmed state.
  static const int outsideConfirmationSamples = 5;
  static const int insideConfirmationSamples = 5;

  // Width of the RSSI boundary zone.
  //
  // Example:
  // If boundary RSSI = -65.8 dBm
  //
  // Inside:
  //     >= -62.8 dBm
  //
  // Boundary:
  //     -62.8 to -68.8 dBm
  //
  // Outside:
  //     <= -68.8 dBm
  static const double boundaryWidthDbm = 3.0;

  // --------------------------------------------------
  // CALIBRATION DATA
  // --------------------------------------------------
  //
  // These values come from the measurements we took
  // using your A18 + Guardian device.
  //
  // Distance      Filtered RSSI
  // --------------------------------
  // 1 m           -47.4 dBm
  // 2 m           -56.0 dBm
  // 3 m           -59.4 dBm
  // 5 m           -61.8 dBm
  // 10 m          -65.8 dBm
  //
  // We use these points to estimate the RSSI
  // corresponding to the selected Guardian Circle range.

  static const List<double> calibrationDistances = [
    1.0,
    2.0,
    3.0,
    5.0,
    10.0,
  ];

  static const List<double> calibrationRssi = [
    -47.4,
    -56.0,
    -59.4,
    -61.8,
    -65.8,
  ];

  // --------------------------------------------------
  // SELECTED GUARDIAN CIRCLE RANGE
  // --------------------------------------------------

  double _boundaryDistanceMeters = 10.0;

  // --------------------------------------------------
  // RSSI WINDOW
  // --------------------------------------------------

  final List<int> _rssiWindow = [];

  // --------------------------------------------------
  // CURRENT STATE
  // --------------------------------------------------

  ProximityState _state =
      ProximityState.signalUncertain;

  int _outsideCount = 0;
  int _insideCount = 0;

  // --------------------------------------------------
  // DYNAMIC THRESHOLDS
  // --------------------------------------------------

  double get boundaryRssi {
    return _estimateRssiForDistance(
      _boundaryDistanceMeters,
    );
  }

  double get insideThreshold {
    return boundaryRssi +
        boundaryWidthDbm;
  }

  double get outsideThreshold {
    return boundaryRssi -
        boundaryWidthDbm;
  }

  // --------------------------------------------------
  // RANGE SETTING
  // --------------------------------------------------

  void setBoundaryDistance(
    double distanceMeters,
  ) {
    if (distanceMeters <= 0) {
      return;
    }

    _boundaryDistanceMeters =
        distanceMeters;

    // Reset state because the meaning of
    // inside/outside has changed.
    reset();
  }

  double get boundaryDistanceMeters =>
      _boundaryDistanceMeters;

  // --------------------------------------------------
  // MAIN RSSI INPUT
  // --------------------------------------------------

  BleProximityResult addRssi(int rssi) {
    _rssiWindow.add(rssi);

    if (_rssiWindow.length > windowSize) {
      _rssiWindow.removeAt(0);
    }

    final filteredRssi =
        _calculateFilteredRssi();

    // Wait for enough readings before making
    // a proximity decision.
    if (_rssiWindow.length < 5) {
      return _buildResult(
        rssi: rssi,
        filteredRssi: filteredRssi,
        confidence: 0.2,
      );
    }

    final confidence =
        _calculateConfidence();

    _updateState(filteredRssi);

    return _buildResult(
      rssi: rssi,
      filteredRssi: filteredRssi,
      confidence: confidence,
    );
  }

  // --------------------------------------------------
  // RSSI ESTIMATION
  // --------------------------------------------------
  //
  // Finds the expected RSSI for a requested distance
  // using linear interpolation between our measured
  // calibration points.
  //
  // Example:
  //
  // 5 m  -> -61.8
  // 10 m -> -65.8
  //
  // Therefore a requested 7.5 m boundary would be
  // approximately halfway between those values.

  double _estimateRssiForDistance(
    double distanceMeters,
  ) {
    // Below our smallest calibration point.
    if (distanceMeters <=
        calibrationDistances.first) {
      return calibrationRssi.first;
    }

    // Above our largest measured point.
    //
    // We extrapolate using the last two measured
    // points, but clamp the result to avoid producing
    // unrealistic values.
    if (distanceMeters >=
        calibrationDistances.last) {
      final lastIndex =
          calibrationDistances.length - 1;

      final previousIndex =
          lastIndex - 1;

      final d1 =
          calibrationDistances[previousIndex];

      final d2 =
          calibrationDistances[lastIndex];

      final r1 =
          calibrationRssi[previousIndex];

      final r2 =
          calibrationRssi[lastIndex];

      final slope =
          (r2 - r1) /
          (d2 - d1);

      final estimated =
          r2 +
          slope *
              (distanceMeters - d2);

      return estimated.clamp(
        -95.0,
        -30.0,
      );
    }

    // Find the two calibration points
    // surrounding the requested distance.
    for (int i = 0;
        i <
            calibrationDistances.length - 1;
        i++) {
      final d1 =
          calibrationDistances[i];

      final d2 =
          calibrationDistances[i + 1];

      if (distanceMeters >= d1 &&
          distanceMeters <= d2) {
        final r1 =
            calibrationRssi[i];

        final r2 =
            calibrationRssi[i + 1];

        final ratio =
            (distanceMeters - d1) /
            (d2 - d1);

        return r1 +
            ((r2 - r1) * ratio);
      }
    }

    return calibrationRssi.last;
  }

  // --------------------------------------------------
  // FILTERING
  // --------------------------------------------------

  double _calculateFilteredRssi() {
    if (_rssiWindow.isEmpty) {
      return 0;
    }

    final sorted =
        List<int>.from(_rssiWindow)..sort();

    // Remove extreme readings when enough samples
    // are available.
    if (sorted.length >= 7) {
      final trimCount =
          max(
        1,
        (sorted.length * 0.2).floor(),
      );

      final start = trimCount;
      final end =
          sorted.length - trimCount;

      if (start < end) {
        final trimmed =
            sorted.sublist(
          start,
          end,
        );

        return trimmed.reduce(
              (a, b) => a + b,
            ) /
            trimmed.length;
      }
    }

    return sorted.reduce(
          (a, b) => a + b,
        ) /
        sorted.length;
  }

  // --------------------------------------------------
  // CONFIDENCE
  // --------------------------------------------------

  double _calculateConfidence() {
    if (_rssiWindow.length < 2) {
      return 0.2;
    }

    final mean =
        _rssiWindow.reduce(
              (a, b) => a + b,
            ) /
            _rssiWindow.length;

    double variance = 0;

    for (final value in _rssiWindow) {
      final difference =
          value - mean;

      variance +=
          difference * difference;
    }

    variance /=
        _rssiWindow.length;

    final standardDeviation =
        sqrt(variance);

    double confidence;

    if (standardDeviation <= 2) {
      confidence = 0.95;
    } else if (standardDeviation <= 4) {
      confidence = 0.80;
    } else if (standardDeviation <= 7) {
      confidence = 0.60;
    } else if (standardDeviation <= 10) {
      confidence = 0.40;
    } else {
      confidence = 0.20;
    }

    final sampleFactor =
        min(
      _rssiWindow.length /
          windowSize,
      1.0,
    );

    confidence *=
        0.5 +
        (sampleFactor * 0.5);

    return confidence.clamp(
      0.0,
      1.0,
    );
  }

  // --------------------------------------------------
  // STATE MACHINE
  // --------------------------------------------------

  void _updateState(
    double filteredRssi,
  ) {
    // -----------------------------------------------
    // OUTSIDE
    // -----------------------------------------------

    if (filteredRssi <=
        outsideThreshold) {
      _outsideCount++;
      _insideCount = 0;

      if (_outsideCount >=
          outsideConfirmationSamples) {
        _state =
            ProximityState.outside;
      }

      return;
    }

    // -----------------------------------------------
    // INSIDE
    // -----------------------------------------------

    if (filteredRssi >=
        insideThreshold) {
      _insideCount++;
      _outsideCount = 0;

      if (_insideCount >=
          insideConfirmationSamples) {
        _state =
            ProximityState.inside;
      }

      return;
    }

    // -----------------------------------------------
    // BOUNDARY
    // -----------------------------------------------

    _insideCount = 0;
    _outsideCount = 0;

    _state =
        ProximityState.boundary;
  }

  // --------------------------------------------------
  // RESULT
  // --------------------------------------------------

  BleProximityResult _buildResult({
    required int rssi,
    required double filteredRssi,
    required double confidence,
  }) {
    return BleProximityResult(
      state: _state,
      rssi: rssi,
      filteredRssi: filteredRssi,
      confidence: confidence,
      sampleCount: _rssiWindow.length,
    );
  }

  // --------------------------------------------------
  // GETTERS
  // --------------------------------------------------

  ProximityState get state => _state;

  double? get filteredRssi {
    if (_rssiWindow.isEmpty) {
      return null;
    }

    return _calculateFilteredRssi();
  }

  int get sampleCount =>
      _rssiWindow.length;

  // --------------------------------------------------
  // RESET
  // --------------------------------------------------

  void reset() {
    _rssiWindow.clear();

    _state =
        ProximityState.signalUncertain;

    _outsideCount = 0;
    _insideCount = 0;
  }
}