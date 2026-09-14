import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:guardian_circle/core/constants/risk_level.dart';
import 'package:guardian_circle/features/dashboard/domain/models/guardian_status.dart';

/// -----------------------------------------------------------------------
/// CAREGIVER DASHBOARD PROVIDER (PHASE 1 PREVIEW)
///
/// In Phase 1, live backend and BLE streams are not yet connected.
/// This provider supplies honest, accessible preview data clearly marked
/// as demo state. It will be replaced with repository/API providers in
/// later integration phases.
/// -----------------------------------------------------------------------

final dashboardPresentationProvider = Provider<DashboardPresentationState>((ref) {
  return DashboardPresentationState.preview();
});

class DashboardPresentationState {
  final GuardianStatus status;
  final String greetingName;
  final String monitoringMessage;
  final bool isPreview;
  final String locationDisplay;
  final String locationSubtext;
  final String movementDisplay;
  final String movementSubtext;
  final String wearableDisplay;
  final String wearableSubtext;
  final List<TimelineEvent> recentActivity;
  final PlannedTrip? plannedTrip;

  const DashboardPresentationState({
    required this.status,
    required this.greetingName,
    required this.monitoringMessage,
    required this.isPreview,
    required this.locationDisplay,
    required this.locationSubtext,
    required this.movementDisplay,
    required this.movementSubtext,
    required this.wearableDisplay,
    required this.wearableSubtext,
    required this.recentActivity,
    this.plannedTrip,
  });

  factory DashboardPresentationState.preview() {
    final now = DateTime.now();
    return DashboardPresentationState(
      greetingName: 'Caregiver',
      monitoringMessage: 'Preview mode — live monitoring is not connected.',
      isPreview: true,
      locationDisplay: 'At Home',
      locationSubtext: 'Inside Home Safe Zone • Preview',
      movementDisplay: 'Looks normal',
      movementSubtext: 'Expected daily activity • Preview',
      wearableDisplay: 'Not connected',
      wearableSubtext: 'Guardian Band not paired',
      status: GuardianStatus(
        riskLevel: RiskLevel.low,
        userName: 'Grandfather',
        safeZoneState: const SafeZoneState(
          status: SafeZoneStatus.insideHome,
          zoneLabel: 'Home',
        ),
        latestEvent: TimelineEvent(
          id: 'evt-returned',
          kind: EventKind.location,
          summary: 'Returned home',
          timestamp: DateTime(now.year, now.month, now.day, 12, 3),
          context: 'Home Safe Zone',
          associatedRisk: RiskLevel.low,
        ),
        lastUpdated: DateTime(now.year, now.month, now.day, 12, 3),
      ),
      recentActivity: [
        TimelineEvent(
          id: 'evt-3',
          kind: EventKind.location,
          summary: 'Returned home',
          timestamp: DateTime(now.year, now.month, now.day, 12, 3),
          context: 'Home Safe Zone',
          associatedRisk: RiskLevel.low,
        ),
        TimelineEvent(
          id: 'evt-2',
          kind: EventKind.location,
          summary: 'Reached market',
          timestamp: DateTime(now.year, now.month, now.day, 11, 18),
          context: 'Market Safe Zone',
          associatedRisk: RiskLevel.low,
        ),
        TimelineEvent(
          id: 'evt-1',
          kind: EventKind.movement,
          summary: 'Left home for routine walk',
          timestamp: DateTime(now.year, now.month, now.day, 10, 42),
          context: 'Residential area',
          associatedRisk: RiskLevel.low,
        ),
      ],
      plannedTrip: PlannedTrip(
        id: 'trip-1',
        label: 'Hospital Check-up',
        start: DateTime(now.year, now.month, now.day, 15, 0),
        end: DateTime(now.year, now.month, now.day, 17, 0),
        destinationZone: 'City Hospital Safe Zone',
        isActive: false,
      ),
    );
  }
}
