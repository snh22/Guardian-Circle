import 'dart:async';
import 'dart:math';

import 'package:sensors_plus/sensors_plus.dart';

class FallDetector {
  // -----------------------------
  // SENSOR VALUES
  // -----------------------------

  double x = 0;
  double y = 0;
  double z = 0;

  double magnitude = 0;
  double peakAcceleration = 0;

  double gyroX = 0;
  double gyroY = 0;
  double gyroZ = 0;

  double gyroMagnitude = 0;
  double peakGyro = 0;

  // -----------------------------
  // FALL DETECTION VALUES
  // -----------------------------

  String status = 'NORMAL';
  String fallState = 'NORMAL';

  double windowPeak = 0;
  double windowGyroPeak = 0;

  int lowMovementCount = 0;

  Timer? impactTimer;

  // -----------------------------
  // SENSOR SUBSCRIPTIONS
  // -----------------------------

  StreamSubscription<UserAccelerometerEvent>?
      accelerometerSubscription;

  StreamSubscription<GyroscopeEvent>? gyroscopeSubscription;

  // -----------------------------
  // CALLBACK
  // -----------------------------

  void Function()? onUpdate;

  // -----------------------------
  // START SENSOR
  // -----------------------------

  void start() {
    // ACCELEROMETER
    accelerometerSubscription =
        userAccelerometerEventStream().listen((event) {
      final newX = event.x;
      final newY = event.y;
      final newZ = event.z;

      final newMagnitude = sqrt(
        newX * newX +
            newY * newY +
            newZ * newZ,
      );

      x = newX;
      y = newY;
      z = newZ;

      magnitude = newMagnitude;

      // Overall acceleration peak
      if (newMagnitude > peakAcceleration) {
        peakAcceleration = newMagnitude;
      }

      // Live status
      if (newMagnitude < 1.5) {
        status = 'LOW ACCELERATION';
      } else if (newMagnitude > 12) {
        status = 'HIGH ACCELERATION';
      } else {
        status = 'NORMAL';
      }

      // -----------------------------
      // FALL DETECTION
      // -----------------------------

      if (fallState == 'NORMAL') {
        if (newMagnitude < 1.5) {
          fallState = 'LOW DETECTED';

          windowPeak = 0;
          windowGyroPeak = 0;

          impactTimer?.cancel();

          impactTimer = Timer(
            const Duration(seconds: 1),
            () {
              if (windowPeak > 12 &&
                  windowGyroPeak > 15) {
                fallState = 'CHECKING AFTER IMPACT';

                lowMovementCount = 0;

                impactTimer = Timer(
                  const Duration(seconds: 2),
                  () {
                    if (lowMovementCount >= 10) {
                      fallState = 'POSSIBLE FALL';
                    } else {
                      fallState = 'NORMAL';
                    }

                    onUpdate?.call();
                  },
                );
              } else {
                fallState = 'NORMAL';
              }

              onUpdate?.call();
            },
          );
        }
      }

      // LOW → IMPACT window
      else if (fallState == 'LOW DETECTED') {
        if (newMagnitude > windowPeak) {
          windowPeak = newMagnitude;
        }

        if (gyroMagnitude > windowGyroPeak) {
          windowGyroPeak = gyroMagnitude;
        }
      }

      // Post-impact movement
      else if (fallState == 'CHECKING AFTER IMPACT') {
        if (newMagnitude < 2.0) {
          lowMovementCount++;
        }
      }

      onUpdate?.call();
    });

    // -----------------------------
    // GYROSCOPE
    // -----------------------------

    gyroscopeSubscription =
        gyroscopeEventStream().listen((event) {
      final newGyroX = event.x;
      final newGyroY = event.y;
      final newGyroZ = event.z;

      final newGyroMagnitude = sqrt(
        newGyroX * newGyroX +
            newGyroY * newGyroY +
            newGyroZ * newGyroZ,
      );

      gyroX = newGyroX;
      gyroY = newGyroY;
      gyroZ = newGyroZ;

      gyroMagnitude = newGyroMagnitude;

      // Overall gyro peak
      if (newGyroMagnitude > peakGyro) {
        peakGyro = newGyroMagnitude;
      }

      // Detection-window gyro peak
      if (fallState == 'LOW DETECTED') {
        if (newGyroMagnitude > windowGyroPeak) {
          windowGyroPeak = newGyroMagnitude;
        }
      }

      onUpdate?.call();
    });
  }

  // -----------------------------
  // RESET PEAKS
  // -----------------------------

  void resetPeak() {
    peakAcceleration = magnitude;
    peakGyro = gyroMagnitude;

    onUpdate?.call();
  }

  // -----------------------------
  // RESET FALL STATE
  // -----------------------------

  void resetFallState() {
    impactTimer?.cancel();

    fallState = 'NORMAL';
    windowPeak = 0;
    windowGyroPeak = 0;
    lowMovementCount = 0;

    onUpdate?.call();
  }

  // -----------------------------
  // CLEANUP
  // -----------------------------

  void dispose() {
    impactTimer?.cancel();

    accelerometerSubscription?.cancel();
    gyroscopeSubscription?.cancel();

    accelerometerSubscription = null;
    gyroscopeSubscription = null;
  }
}

