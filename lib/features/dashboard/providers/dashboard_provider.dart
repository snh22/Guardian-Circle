import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/risk_level.dart';
import '../domain/models/guardian_status.dart';

/// -----------------------------------------------------------------------
/// WHY RIVERPOD
/// Guardian Circle's dashboard is fed by three independent async sources
/// that all need to converge into one screen:
///   1. BLE characteristic notifications from the band (movement, SOS)
///   2. GPS / geofence stream from the phone
///   3. Backend risk-engine result, delivered over WebSocket with a REST
///      polling fallback
/// Riverpod's StreamProvider/AsyncNotifier composition lets each source own
/// its lifecycle (retry, dispose, reconnect) while the dashboard just
/// watches a single combined provider — no manual setState plumbing, and
/// screens rebuild only for the slice of state they actually watch.
/// -----------------------------------------------------------------------

/// Raw stream of risk-engine results (backend WebSocket).
/// Swap the mock generator for a real ws:// connection in RiskEngineService.
final riskEngineStreamProvider = StreamProvider<RiskLevel>((ref) {
  return const Stream<RiskLevel>.empty(); // wire to RiskEngineService.stream()
});

/// Raw stream of timeline events (movement, BLE, SOS, fall-like, trips).
final eventTimelineStreamProvider = StreamProvider<TimelineEvent>((ref) {
  return const Stream<TimelineEvent>.empty(); // wire to EventService.stream()
});

/// Band telemetry (connection state + battery) — populated by the BLE
/// feature's own provider (see features/ble/providers). Re-exposed here so
/// the dashboard doesn't need to depend on the BLE module directly.
final bandTelemetryProvider = StateProvider<BandTelemetry>((ref) {
  return const BandTelemetry(connectionState: BandConnectionState.disconnected);
});

final safeZoneStateProvider = StateProvider<SafeZoneState>((ref) {
  return const SafeZoneState(status: SafeZoneStatus.unknown, zoneLabel: 'Home Zone');
});

/// The single source of truth the Dashboard screen watches.
/// Combines risk level + zone + latest event + band battery into one
/// immutable snapshot, recomputed whenever any input changes.
final guardianStatusProvider = Provider<AsyncValue<GuardianStatus>>((ref) {
  final riskAsync = ref.watch(riskEngineStreamProvider);
  final eventAsync = ref.watch(eventTimelineStreamProvider);
  final zone = ref.watch(safeZoneStateProvider);
  final band = ref.watch(bandTelemetryProvider);

  // Until the first real values arrive, show a safe, honest placeholder
  // rather than blocking the whole dashboard on every stream.
  final risk = riskAsync.valueOrNull ?? RiskLevel.low;
  final event = eventAsync.valueOrNull ??
      TimelineEvent(
        id: 'placeholder',
        kind: EventKind.movement,
        summary: 'Waiting for first signal…',
        timestamp: DateTime.now(),
      );

  final error = riskAsync.error ?? eventAsync.error;
  if (error != null) {
    return AsyncValue.error(error, StackTrace.current);
  }

  return AsyncValue.data(
    GuardianStatus(
      riskLevel: risk,
      userName: 'Kamala Devi', // replace with authenticated caregiver's linked user
      safeZoneState: zone,
      latestEvent: event,
      batteryPercent: band.batteryPercent,
      lastUpdated: DateTime.now(),
    ),
  );
});

/// Rolling event history for the timeline widget (kept separate from the
/// single-status provider so a long list doesn't force full-card rebuilds).
class TimelineController extends StateNotifier<List<TimelineEvent>> {
  TimelineController() : super(const []);

  static const int _maxRetained = 50;

  void addEvent(TimelineEvent event) {
    state = [event, ...state].take(_maxRetained).toList();
  }

  void acknowledgeLatest() {
    if (state.isEmpty) return;
    // In production this calls the backend ack endpoint, then optimistically
    // updates local state so the caregiver gets instant feedback.
  }
}

final timelineControllerProvider =
    StateNotifierProvider<TimelineController, List<TimelineEvent>>(
  (ref) => TimelineController(),
);

/// True whenever the current risk level demands the full-screen escalation
/// modal (Critical: strong SOS / fall-like event).
final shouldShowEscalationModalProvider = Provider<bool>((ref) {
  final status = ref.watch(guardianStatusProvider).valueOrNull;
  return status?.riskLevel.requiresFullScreenAlert ?? false;
});