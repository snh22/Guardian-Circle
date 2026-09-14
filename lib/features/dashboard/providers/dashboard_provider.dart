import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/risk_level.dart';
import '../../../core/network/api_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../domain/models/guardian_status.dart';

/// ----------------------------------------------------------------------
/// Real backend wiring. This file used to hold two Stream.empty()
/// placeholders — this is the swap for the real thing.
///
/// BLE/GPS sensor input isn't built yet, so the risk request below sends
/// a hardcoded "everything normal" reading just to prove the round-trip
/// works. The RISK LEVEL that comes back is real (computed by the actual
/// backend) — only the input feeding it is a placeholder.
/// ----------------------------------------------------------------------

/// POST /api/v1/risk/analyze
final riskAnalysisProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  return ApiService.analyzeRisk(
    movement: 'normal',
    locationStatus: 'known',
    tripStatus: 'none',
    eventType: 'movement',
  );
});

/// GET /api/v1/events/user/{user_id}
/// Named exactly `dashboardEventsProvider` because dashboard_screen.dart
/// already watches it under that name.
final dashboardEventsProvider =
    FutureProvider.autoDispose<List<TimelineEvent>>((ref) async {
  final user = ref.watch(authControllerProvider).user;
  if (user == null) return const [];
  return ApiService.getEventsForUser(user.userId);
});

/// Band telemetry (connection state + battery) — populated by the BLE
/// feature's own provider later. Re-exposed here so the dashboard doesn't
/// need to depend on the BLE module directly.
final bandTelemetryProvider = StateProvider<BandTelemetry>((ref) {
  return const BandTelemetry(connectionState: BandConnectionState.disconnected);
});

final safeZoneStateProvider = StateProvider<SafeZoneState>((ref) {
  return const SafeZoneState(status: SafeZoneStatus.unknown, zoneLabel: 'Home Zone');
});

/// The single source of truth the Dashboard screen watches.
final guardianStatusProvider = Provider<AsyncValue<GuardianStatus>>((ref) {
  final riskAsync = ref.watch(riskAnalysisProvider);
  final eventsAsync = ref.watch(dashboardEventsProvider);
  final zone = ref.watch(safeZoneStateProvider);
  final band = ref.watch(bandTelemetryProvider);
  final user = ref.watch(authControllerProvider).user;

  if (riskAsync.isLoading || eventsAsync.isLoading) {
    return const AsyncValue.loading();
  }

  final error = riskAsync.error ?? eventsAsync.error;
  if (error != null) {
    return AsyncValue.error(error, StackTrace.current);
  }

  final riskData = riskAsync.valueOrNull;
  final risk = riskData != null
      ? riskLevelFromString(riskData['risk_level'] as String? ?? 'low')
      : RiskLevel.low;

  final events = eventsAsync.valueOrNull ?? const <TimelineEvent>[];
  final latestEvent = events.isNotEmpty
      ? events.first
      : TimelineEvent(
          id: 'placeholder',
          kind: EventKind.movement,
          summary: 'Waiting for first signal…',
          timestamp: DateTime.now(),
        );

  return AsyncValue.data(
    GuardianStatus(
      riskLevel: risk,
      userName: user?.name ?? 'Guardian Circle',
      safeZoneState: zone,
      latestEvent: latestEvent,
      batteryPercent: band.batteryPercent,
      lastUpdated: DateTime.now(),
    ),
  );
});

/// Refetches risk + events from the backend. Called by the dashboard's
/// pull-to-refresh, the acknowledge button, and the escalation screen.
Future<void> refreshDashboard(WidgetRef ref) async {
  ref.invalidate(riskAnalysisProvider);
  ref.invalidate(dashboardEventsProvider);
}

/// True whenever the current risk level demands the full-screen escalation
/// modal (Critical: strong SOS / fall-like event).
final shouldShowEscalationModalProvider = Provider<bool>((ref) {
  final status = ref.watch(guardianStatusProvider).valueOrNull;
  return status?.riskLevel.requiresFullScreenAlert ?? false;
});