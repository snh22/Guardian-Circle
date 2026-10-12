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
// SENSITIVE FALL DETECTION VALUES
// -----------------------------

static const double lowAccelerationThreshold = 2.5;
static const double impactAccelerationThreshold = 8.0;
static const double impactGyroThreshold = 6.0;
static const double postImpactMovementThreshold = 3.0;

static const int requiredLowMovementReadings = 3;

static const Duration impactWindowDuration =
Duration(milliseconds: 1500);

static const Duration postImpactObservationDuration =
Duration(milliseconds: 2500);

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
// Prevent duplicate sensor subscriptions.
if (accelerometerSubscription != null ||
gyroscopeSubscription != null) {
return;
}


// -----------------------------
// ACCELEROMETER
// -----------------------------

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

  // Overall acceleration peak.
  if (newMagnitude > peakAcceleration) {
    peakAcceleration = newMagnitude;
  }

  // Live sensor status.
  if (newMagnitude < lowAccelerationThreshold) {
    status = 'LOW ACCELERATION';
  } else if (newMagnitude > 6.0) {
    status = 'HIGH ACCELERATION';
  } else {
    status = 'NORMAL';
  }

  // -----------------------------
  // FALL DETECTION
  // -----------------------------

  if (fallState == 'NORMAL') {
    // Detect a possible low-acceleration phase.
    if (newMagnitude < lowAccelerationThreshold) {
      fallState = 'LOW DETECTED';

      windowPeak = 0;
      windowGyroPeak = gyroMagnitude;
      lowMovementCount = 0;

      impactTimer?.cancel();

      // Wait for the impact phase.
      impactTimer = Timer(
        impactWindowDuration,
        () {
          if (fallState != 'LOW DETECTED') {
            return;
          }

          if (windowPeak > impactAccelerationThreshold &&
              windowGyroPeak > impactGyroThreshold) {
            fallState = 'CHECKING AFTER IMPACT';

            lowMovementCount = 0;

            impactTimer = Timer(
              postImpactObservationDuration,
              () {
                if (fallState != 'CHECKING AFTER IMPACT') {
                  return;
                }

                if (lowMovementCount >=
                    requiredLowMovementReadings) {
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
  } else if (fallState == 'LOW DETECTED') {
    // Track acceleration peaks during the impact window.
    if (newMagnitude > windowPeak) {
      windowPeak = newMagnitude;
    }

    // Track gyroscope peaks from the latest sensor values.
    if (gyroMagnitude > windowGyroPeak) {
      windowGyroPeak = gyroMagnitude;
    }
  } else if (fallState == 'CHECKING AFTER IMPACT') {
    // Count low-acceleration readings after the impact.
    if (newMagnitude < postImpactMovementThreshold) {
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

  // Overall gyroscope peak.
  if (newGyroMagnitude > peakGyro) {
    peakGyro = newGyroMagnitude;
  }

  // Detection-window gyroscope peak.
  if (fallState == 'LOW DETECTED' &&
      newGyroMagnitude > windowGyroPeak) {
    windowGyroPeak = newGyroMagnitude;
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
impactTimer = null;


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
impactTimer = null;


accelerometerSubscription?.cancel();
gyroscopeSubscription?.cancel();

accelerometerSubscription = null;
gyroscopeSubscription = null;


}
}