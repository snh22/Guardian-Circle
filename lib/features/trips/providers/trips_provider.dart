import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../domain/models/planned_trip.dart';

/// Real trip list for the logged-in caregiver's linked user.
final tripsProvider = FutureProvider.autoDispose<List<PlannedTrip>>((ref) async {
  final user = ref.watch(authControllerProvider).user;
  if (user == null) return [];
  return ApiService.getTripsForUser(user.userId);
});

/// Drives the "add trip" form — submits to the backend, then refreshes
/// the list so the new trip shows up immediately.
class AddTripController extends StateNotifier<AsyncValue<void>> {
  AddTripController(this._ref) : super(const AsyncValue.data(null));

  final Ref _ref;

  Future<bool> submit({
    required String destination,
    required DateTime startTime,
  }) async {
    final user = _ref.read(authControllerProvider).user;
    if (user == null) return false;

    state = const AsyncValue.loading();
    try {
      await ApiService.createTrip(
        userId: user.userId,
        destination: destination,
        startTime: startTime,
      );
      _ref.invalidate(tripsProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final addTripControllerProvider =
    StateNotifierProvider.autoDispose<AddTripController, AsyncValue<void>>(
  (ref) => AddTripController(ref),
);