import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/risk_level.dart';
import '../domain/models/guardian_status.dart';
import '../services/fall_event_service.dart';

final fallEventServiceProvider = Provider<FallEventService>((ref) {
  return FallEventService();
});

final acknowledgedEventIdProvider = StateProvider<String?>((ref) {
  return null;
});

final fallEventStreamProvider = Provider<Stream<TimelineEvent>>((ref) {
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
      summary: 'Fall detected — immediate attention required',
      timestamp: timestamp,
      associatedRisk: RiskLevel.critical,
    );
  }).asBroadcastStream();
});

final riskEngineStreamProvider = StreamProvider<RiskLevel>((ref) {
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

final bandTelemetryProvider = StateProvider<BandTelemetry>((ref) {
  return const BandTelemetry(
    connectionState: BandConnectionState.disconnected,
  );
});

final safeZoneStateProvider = StateProvider<SafeZoneState>((ref) {
  return const SafeZoneState(
    status: SafeZoneStatus.unknown,
    zoneLabel: 'Home Zone',
  );
});

final guardianStatusProvider =
    Provider<AsyncValue<GuardianStatus>>((ref) {
  final riskAsync = ref.watch(riskEngineStreamProvider);
  final eventAsync = ref.watch(eventTimelineStreamProvider);
  final zone = ref.watch(safeZoneStateProvider);
  final band = ref.watch(bandTelemetryProvider);

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
    return AsyncValue.error(
      error,
      StackTrace.current,
    );
  }

  return AsyncValue.data(
    GuardianStatus(
      riskLevel: risk,
      userName: 'Baapu',
      safeZoneState: zone,
      latestEvent: event,
      batteryPercent: band.batteryPercent,
      lastUpdated: DateTime.now(),
    ),
  );
});

class TimelineController
    extends StateNotifier<List<TimelineEvent>> {
  final VoidCallback _onAcknowledge;

  TimelineController(this._onAcknowledge)
      : super(const []);

  static const int _maxRetained = 50;

  void addEvent(TimelineEvent event) {
    state = [event, ...state].take(_maxRetained).toList();
  }

  Future<void> acknowledgeLatest() async {
    _onAcknowledge();

    state = [
      TimelineEvent(
        id: 'acknowledged-${DateTime.now().millisecondsSinceEpoch}',
        kind: EventKind.checkIn,
        summary: 'Fall alert acknowledged',
        timestamp: DateTime.now(),
      ),
      ...state.skip(1),
    ];
  }
}

final timelineControllerProvider =
    StateNotifierProvider<TimelineController, List<TimelineEvent>>(
  (ref) => TimelineController(
    () {
      final event =
          ref.read(eventTimelineStreamProvider).valueOrNull;

      if (event != null && event.kind == EventKind.fallLike) {
        ref.read(acknowledgedEventIdProvider.notifier).state =
            event.id;
      }
    },
  ),
);

final shouldShowEscalationModalProvider = Provider<bool>((ref) {
  final status = ref.watch(guardianStatusProvider).valueOrNull;

  return status?.riskLevel.requiresFullScreenAlert ?? false;
});