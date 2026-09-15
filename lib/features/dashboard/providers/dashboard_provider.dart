import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/risk_level.dart';
import '../../../../core/network/api_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../domain/models/guardian_status.dart';
import '../services/fall_event_service.dart';

// ================================================================
// FALL EVENT SERVICE
// ================================================================

final fallEventServiceProvider = Provider<FallEventService>((ref) {
  return FallEventService();
});

// ================================================================
// ACKNOWLEDGED FALL EVENT
// ================================================================

final acknowledgedEventIdProvider =
    StateProvider<String?>((ref) {
  return null;
});

// ================================================================
// REAL BACKEND RISK ANALYSIS
// ================================================================

final riskAnalysisProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>(
  (ref) async {
    return ApiService.analyzeRisk(
      movement: 'normal',
      locationStatus: 'known',
      tripStatus: 'none',
      eventType: 'movement',
    );
  },
);

// ================================================================
// DASHBOARD EVENTS
// ================================================================

final dashboardEventsProvider =
    FutureProvider.autoDispose<List<TimelineEvent>>(
  (ref) async {
    final user = ref.watch(authControllerProvider).user;

    if (user == null) {
      return const [];
    }

    return ApiService.getEventsForUser(user.userId);
  },
);

// ================================================================
// FALL EVENT STREAM
// ================================================================

final fallEventStreamProvider =
    Provider<Stream<TimelineEvent>>((ref) {
  final service = ref.watch(fallEventServiceProvider);

  return Stream.periodic(
    const Duration(seconds: 3),
    (_) {},
  ).asyncMap((_) async {
    final data = await service.fetchLatestEvent();

    if (data == null || data['event'] != 'fall') {
      return TimelineEvent(
        id: 'waiting',
        kind: EventKind.movement,
        summary: 'Waiting for first signal…',
        timestamp: DateTime.now(),
      );
    }

    final eventId =
        data['event_id']?.toString() ?? 'unknown-fall';

    final timestampString =
        data['timestamp']?.toString();

    final timestamp = timestampString != null
        ? DateTime.tryParse(timestampString) ??
            DateTime.now()
        : DateTime.now();

    return TimelineEvent(
      id: eventId,
      kind: EventKind.fallLike,
      summary:
          'Fall detected — immediate attention required',
      timestamp: timestamp,
      associatedRisk: RiskLevel.critical,
    );
  }).asBroadcastStream();
});

// ================================================================
// FALL EVENT RISK ENGINE
// ================================================================

final riskEngineStreamProvider =
    StreamProvider<RiskLevel>((ref) {
  final acknowledgedEventId =
      ref.watch(acknowledgedEventIdProvider);

  return ref.watch(fallEventStreamProvider).map(
        (event) {
          if (event.kind == EventKind.fallLike &&
              event.id == acknowledgedEventId) {
            return RiskLevel.low;
          }

          return event.associatedRisk ?? RiskLevel.low;
        },
      );
});

final eventTimelineStreamProvider =
    StreamProvider<TimelineEvent>((ref) {
  return ref.watch(fallEventStreamProvider);
});

// ================================================================
// BAND TELEMETRY
// ================================================================

final bandTelemetryProvider =
    StateProvider<BandTelemetry>((ref) {
  return const BandTelemetry(
    connectionState:
        BandConnectionState.disconnected,
  );
});

// ================================================================
// SAFE ZONE
// ================================================================

final safeZoneStateProvider =
    StateProvider<SafeZoneState>((ref) {
  return const SafeZoneState(
    status: SafeZoneStatus.unknown,
    zoneLabel: 'Home Zone',
  );
});

// ================================================================
// GUARDIAN STATUS
// ================================================================

final guardianStatusProvider =
    Provider<AsyncValue<GuardianStatus>>((ref) {
  final riskAsync = ref.watch(riskAnalysisProvider);
  final eventsAsync =
      ref.watch(dashboardEventsProvider);

  final zone = ref.watch(safeZoneStateProvider);
  final band = ref.watch(bandTelemetryProvider);
  final user =
      ref.watch(authControllerProvider).user;

  if (riskAsync.isLoading ||
      eventsAsync.isLoading) {
    return const AsyncValue.loading();
  }

  final error =
      riskAsync.error ?? eventsAsync.error;

  if (error != null) {
    return AsyncValue.error(
      error,
      StackTrace.current,
    );
  }

  final riskData = riskAsync.valueOrNull;

  final backendRisk =
      riskData != null
          ? riskLevelFromString(
              riskData['risk_level']
                      as String? ??
                  'low',
            )
          : RiskLevel.low;

  final events =
      eventsAsync.valueOrNull ??
          const <TimelineEvent>[];

  final latestEvent = events.isNotEmpty
      ? events.first
      : TimelineEvent(
          id: 'placeholder',
          kind: EventKind.movement,
          summary:
              'Waiting for first signal…',
          timestamp: DateTime.now(),
        );

  return AsyncValue.data(
    GuardianStatus(
      riskLevel: backendRisk,
      userName:
          user?.name ?? 'Guardian Circle',
      safeZoneState: zone,
      latestEvent: latestEvent,
      batteryPercent:
          band.batteryPercent,
      lastUpdated: DateTime.now(),
    ),
  );
});

// ================================================================
// TIMELINE CONTROLLER
// ================================================================

class TimelineController
    extends StateNotifier<List<TimelineEvent>> {
  final VoidCallback _onAcknowledge;

  TimelineController(this._onAcknowledge)
      : super(const []);

  static const int _maxRetained = 50;

  void addEvent(TimelineEvent event) {
    state = [
      event,
      ...state,
    ].take(_maxRetained).toList();
  }

  Future<void> acknowledgeLatest() async {
    _onAcknowledge();

    state = [
      TimelineEvent(
        id:
            'acknowledged-'
            '${DateTime.now().millisecondsSinceEpoch}',
        kind: EventKind.checkIn,
        summary: 'Fall alert acknowledged',
        timestamp: DateTime.now(),
      ),
      ...state.skip(1),
    ];
  }
}

final timelineControllerProvider =
    StateNotifierProvider<
        TimelineController,
        List<TimelineEvent>>(
  (ref) => TimelineController(
    () {
      final event = ref
          .read(eventTimelineStreamProvider)
          .valueOrNull;

      if (event != null &&
          event.kind == EventKind.fallLike) {
        ref
            .read(
              acknowledgedEventIdProvider
                  .notifier,
            )
            .state = event.id;
      }
    },
  ),
);

// ================================================================
// REFRESH DASHBOARD
// ================================================================

Future<void> refreshDashboard(
  WidgetRef ref,
) async {
  ref.invalidate(riskAnalysisProvider);
  ref.invalidate(dashboardEventsProvider);
}

// ================================================================
// ESCALATION MODAL
// ================================================================

final shouldShowEscalationModalProvider =
    Provider<bool>((ref) {
  final status =
      ref.watch(guardianStatusProvider)
          .valueOrNull;

  return status
          ?.riskLevel
          .requiresFullScreenAlert ??
      false;
});
