import 'package:flutter_test/flutter_test.dart';
import 'package:guardian_circle/proximity/ble_proximity_engine.dart';

void main() {
  group('BleProximityEngine', () {
    test('smooths RSSI using a rolling average', () {
      final engine = BleProximityEngine();

      engine.addRssi(-50);
      engine.addRssi(-52);
      engine.addRssi(-54);

      expect(engine.rawRssi, -54);
      expect(engine.smoothedRssi, closeTo(-52.0, 0.001));
    });

    test('strong sustained RSSI becomes close', () {
      final engine = BleProximityEngine();

      for (var i = 0; i < 3; i++) {
        engine.addRssi(-60);
      }

      expect(engine.state, 'close');
      expect(engine.proximityLabel, 'Within ~5 m');
    });

    test('middle RSSI becomes near after confirmation', () {
      final engine = BleProximityEngine();

      for (var i = 0; i < 3; i++) {
        engine.addRssi(-78);
      }

      expect(engine.state, 'near');
      expect(engine.proximityLabel, '~5–10 m');
    });

    test('weak sustained RSSI becomes far', () {
      final engine = BleProximityEngine();

      for (var i = 0; i < 3; i++) {
        engine.addRssi(-88);
      }

      expect(engine.state, 'far');
      expect(engine.proximityLabel, 'Beyond ~10 m');
    });

    test('single noisy reading does not immediately change state', () {
      final engine = BleProximityEngine();

      for (var i = 0; i < 3; i++) {
        engine.addRssi(-60);
      }

      expect(engine.state, 'close');

      engine.addRssi(-90);

      expect(engine.state, isNot('far'));
    });

    test('signal loss is separate from weak RSSI', () {
      final engine = BleProximityEngine();

      engine.addRssi(-88);
      expect(engine.state, isNot('signal_lost'));

      engine.markSignalLost();

      expect(engine.state, 'signal_lost');
      expect(engine.proximityLabel, 'Patient Signal Lost');
    });

    test('reset clears RSSI processing state', () {
      final engine = BleProximityEngine();

      engine.addRssi(-60);
      engine.addRssi(-60);
      engine.addRssi(-60);

      engine.reset();

      expect(engine.sampleCount, 0);
      expect(engine.rawRssi, isNull);
      expect(engine.smoothedRssi, isNull);
      expect(engine.state, 'unknown');
    });
  });
}
