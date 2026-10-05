import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_service.dart';

import '../../domain/models/planned_trip.dart';
import '../../providers/trips_provider.dart';

class TripsScreen extends ConsumerWidget {
  const TripsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripsAsync = ref.watch(tripsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF163B68),
        foregroundColor: Colors.white,
        title: const Text(
          'Planned Trips',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddTripSheet(context, ref),
        backgroundColor: const Color(0xFF24598B),
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Add Trip',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: tripsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(
            color: Color(0xFF24598B),
          ),
        ),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: _ErrorState(
              message: 'Could not load planned trips.',
              onRetry: () => ref.invalidate(tripsProvider),
            ),
          ),
        ),
        data: (trips) {
          return RefreshIndicator(
            color: const Color(0xFF24598B),
            onRefresh: () async {
              ref.invalidate(tripsProvider);
              await ref.read(tripsProvider.future);
            },
            child: trips.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(height: 100),
                      _EmptyTripsState(),
                    ],
                  )
                : ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    children: [
                      _TripsHeader(trips: trips),
                      const SizedBox(height: 16),
                      ...trips.map(
                        (trip) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _TripCard(trip: trip),
                        ),
                      ),
                    ],
                  ),
          );
        },
      ),
    );
  }

  void _showAddTripSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AddTripSheet(),
    );
  }
}

class _TripsHeader extends StatelessWidget {
  final List<PlannedTrip> trips;

  const _TripsHeader({required this.trips});

  @override
  Widget build(BuildContext context) {
    final active = trips.where((trip) => trip.isActive).length;
    final planned = trips.where((trip) => trip.isPlanned).length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF163B68),
            Color(0xFF24598B),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF183B60).withValues(alpha: 0.10),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.16),
              ),
            ),
            child: const Icon(
              Icons.route_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Trip Planning',
                  style: TextStyle(
                    color: Color(0xFFBFD8EE),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${trips.length} ${trips.length == 1 ? 'trip' : 'trips'} scheduled',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '$planned planned  •  $active active',
                  style: const TextStyle(
                    color: Color(0xFFD8E7F5),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TripCard extends ConsumerWidget {
  final PlannedTrip trip;

  const _TripCard({required this.trip});

  Color get _statusColor => switch (trip.status.toLowerCase()) {
        'active' => const Color(0xFF1E8E5A),
        'completed' => const Color(0xFF7C8797),
        'cancelled' => const Color(0xFFD9534F),
        _ => const Color(0xFF24598B),
      };

  IconData get _statusIcon => switch (trip.status.toLowerCase()) {
        'active' => Icons.navigation_rounded,
        'completed' => Icons.check_circle_outline_rounded,
        'cancelled' => Icons.cancel_outlined,
        _ => Icons.schedule_rounded,
      };

  String get _statusLabel {
    switch (trip.status.toLowerCase()) {
      case 'active':
        return 'Active';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'Planned';
    }
  }

  String get _tripDescription {
    switch (trip.status.toLowerCase()) {
      case 'active':
        return 'This planned journey is currently active.';
      case 'completed':
        return 'This planned journey has been completed.';
      case 'cancelled':
        return 'This planned journey was cancelled.';
      default:
        return 'This journey is scheduled for the patient.';
    }
  }

  IconData get _descriptionIcon {
    switch (trip.status.toLowerCase()) {
      case 'active':
        return Icons.navigation_rounded;
      case 'completed':
        return Icons.check_circle_outline_rounded;
      case 'cancelled':
        return Icons.info_outline_rounded;
      default:
        return Icons.event_available_rounded;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isActive = trip.isActive;

    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFE6EBF2),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF183B60).withValues(alpha: 0.055),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  Icons.location_on_rounded,
                  color: _statusColor,
                  size: 25,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'DESTINATION',
                      style: TextStyle(
                        color: Color(0xFF8994A3),
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.9,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      trip.destination,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF183B60),
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _statusIcon,
                      size: 13,
                      color: _statusColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _statusLabel,
                      style: TextStyle(
                        color: _statusColor,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),

          // Planned journey information
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 11,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFD),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFFE8EDF3),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_month_outlined,
                  size: 19,
                  color: Color(0xFF24598B),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'SCHEDULED JOURNEY',
                        style: TextStyle(
                          color: Color(0xFF8994A3),
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.7,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _formatDateTime(trip.startTime),
                        style: const TextStyle(
                          color: Color(0xFF354052),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Safety context
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 11,
            ),
            decoration: BoxDecoration(
              color: _statusColor.withValues(alpha: 0.055),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(
                  _descriptionIcon,
                  size: 18,
                  color: _statusColor,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    _tripDescription,
                    style: TextStyle(
                      color: _statusColor,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (isActive) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F7EF),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFFCDEBDD),
                ),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.shield_outlined,
                    size: 18,
                    color: Color(0xFF1E8E5A),
                  ),
                  SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      'Trip monitoring is available through Live Location.',
                      style: TextStyle(
                        color: Color(0xFF1E8E5A),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (trip.isPlanned) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _editTrip(context, ref),
                    icon: const Icon(Icons.edit_outlined, size: 17),
                    label: const Text('Edit Trip'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF24598B),
                      side: const BorderSide(
                        color: Color(0xFFB9C9D9),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _cancelTrip(context, ref),
                    icon: const Icon(Icons.cancel_outlined, size: 17),
                    label: const Text('Cancel Trip'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFD9534F),
                      side: const BorderSide(
                        color: Color(0xFFE9B7B4),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _editTrip(BuildContext context, WidgetRef ref) async {
    final destinationController =
        TextEditingController(text: trip.destination);
    DateTime selectedDateTime = trip.startTime;

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              title: const Text(
                'Edit Trip',
                style: TextStyle(
                  color: Color(0xFF183B60),
                  fontWeight: FontWeight.w900,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: destinationController,
                    decoration: InputDecoration(
                      labelText: 'Destination',
                      prefixIcon: const Icon(Icons.location_on_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate:
                            selectedDateTime.isBefore(DateTime.now())
                                ? DateTime.now()
                                : selectedDateTime,
                        firstDate: DateTime.now(),
                        lastDate:
                            DateTime.now().add(const Duration(days: 365)),
                        builder: (context, child) => Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: const ColorScheme.light(
                              primary: Color(0xFF24598B),
                            ),
                          ),
                          child: child!,
                        ),
                      );

                      if (date == null || !context.mounted) return;

                      final time = await showTimePicker(
                        context: context,
                        initialTime:
                            TimeOfDay.fromDateTime(selectedDateTime),
                        builder: (context, child) => Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: const ColorScheme.light(
                              primary: Color(0xFF24598B),
                            ),
                          ),
                          child: child!,
                        ),
                      );

                      if (time == null) return;

                      setDialogState(() {
                        selectedDateTime = DateTime(
                          date.year,
                          date.month,
                          date.day,
                          time.hour,
                          time.minute,
                        );
                      });
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFD),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFFE1E7EF),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_month_outlined,
                            color: Color(0xFF24598B),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _formatDateTime(selectedDateTime),
                              style: const TextStyle(
                                color: Color(0xFF354052),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.edit_calendar_outlined,
                            size: 18,
                            color: Color(0xFF8994A3),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () =>
                      Navigator.of(dialogContext).pop(false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () async {
                    final destination =
                        destinationController.text.trim();

                    if (destination.isEmpty) return;

                    await ApiService.updateTrip(
                      tripId: trip.tripId,
                      destination: destination,
                      startTime: selectedDateTime,
                    );

                    if (dialogContext.mounted) {
                      Navigator.of(dialogContext).pop(true);
                    }
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF24598B),
                  ),
                  child: const Text('Save Changes'),
                ),
              ],
            );
          },
        );
      },
    );

    destinationController.dispose();

    if (result == true) {
      ref.invalidate(tripsProvider);
    }
  }

  Future<void> _cancelTrip(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text(
            'Cancel Trip?',
            style: TextStyle(
              color: Color(0xFF183B60),
              fontWeight: FontWeight.w900,
            ),
          ),
          content: Text(
            'Cancel the trip to ${trip.destination}? The trip will remain in your history as cancelled.',
            style: const TextStyle(
              color: Color(0xFF5F6B7A),
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Keep Trip'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFD9534F),
              ),
              child: const Text('Cancel Trip'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) return;

    try {
      await ApiService.updateTrip(
        tripId: trip.tripId,
        status: 'cancelled',
      );

      ref.invalidate(tripsProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Trip cancelled successfully.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to cancel the trip. Please try again.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  String _formatDateTime(DateTime t) {
    final hour = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final minute = t.minute.toString().padLeft(2, '0');
    final period = t.hour >= 12 ? 'PM' : 'AM';

    return '${t.day}/${t.month}/${t.year}  •  $hour:$minute $period';
  }
}

class _EmptyTripsState extends StatelessWidget {
  const _EmptyTripsState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Container(
            width: 92,
            height: 92,
            decoration: const BoxDecoration(
              color: const Color(0xFFEAF1F8),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.route_rounded,
              size: 44,
              color: Color(0xFF24598B),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'No Planned Trips',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF183B60),
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add a trip when the patient is expected to travel. '
            'This helps Guardian Circle understand planned movement '
            'and reduce unnecessary risk alerts.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF7C8797),
              fontSize: 12.5,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F5FA),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFFDCE6F0),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.add_rounded,
                  size: 17,
                  color: Color(0xFF24598B),
                ),
                SizedBox(width: 6),
                Text(
                  'Use “Add Trip” to create one',
                  style: TextStyle(
                    color: Color(0xFF24598B),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.error_outline_rounded,
          size: 50,
          color: Color(0xFFD9534F),
        ),
        const SizedBox(height: 12),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF354052),
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: onRetry,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF24598B),
            foregroundColor: Colors.white,
          ),
          child: const Text('Retry'),
        ),
      ],
    );
  }
}

class _AddTripSheet extends ConsumerStatefulWidget {
  const _AddTripSheet();

  @override
  ConsumerState<_AddTripSheet> createState() => _AddTripSheetState();
}

class _AddTripSheetState extends ConsumerState<_AddTripSheet> {
  final _destinationController = TextEditingController();
  DateTime? _selectedDateTime;

  @override
  void dispose() {
    _destinationController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF24598B),
            ),
          ),
          child: child!,
        );
      },
    );

    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF24598B),
            ),
          ),
          child: child!,
        );
      },
    );

    if (time == null) return;

    setState(() {
      _selectedDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _submit() async {
    if (_destinationController.text.trim().isEmpty ||
        _selectedDateTime == null) {
      return;
    }

    final success =
        await ref.read(addTripControllerProvider.notifier).submit(
              destination: _destinationController.text.trim(),
              startTime: _selectedDateTime!,
            );

    if (success && mounted) {
      Navigator.of(context).pop();
    }
  }

  InputDecoration _inputDecoration() {
    return InputDecoration(
      labelText: 'Destination',
      hintText: 'Where is the patient going?',
      prefixIcon: const Icon(
        Icons.location_on_outlined,
        color: Color(0xFF24598B),
      ),
      filled: true,
      fillColor: const Color(0xFFF8FAFD),
      labelStyle: const TextStyle(
        color: Color(0xFF6D7888),
        fontWeight: FontWeight.w600,
      ),
      hintStyle: const TextStyle(
        color: Color(0xFFA5AFBC),
        fontSize: 13,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(
          color: Color(0xFFE4EAF1),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(
          color: Color(0xFFE4EAF1),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(
          color: Color(0xFF24598B),
          width: 1.5,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final submitState = ref.watch(addTripControllerProvider);
    final isLoading = submitState.isLoading;

    return SafeArea(
      child: Container(
        padding: EdgeInsets.fromLTRB(
          20,
          10,
          20,
          MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(28),
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD6DDE6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF1F8),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.add_road_rounded,
                      color: Color(0xFF24598B),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Add Planned Trip',
                          style: TextStyle(
                            color: Color(0xFF183B60),
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Tell Guardian Circle about the patient’s travel plan',
                          style: TextStyle(
                            color: Color(0xFF8994A3),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              TextField(
                controller: _destinationController,
                textCapitalization: TextCapitalization.words,
                decoration: _inputDecoration(),
              ),
              const SizedBox(height: 13),
              InkWell(
                onTap: _pickDateTime,
                borderRadius: BorderRadius.circular(15),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 15,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFD),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: const Color(0xFFE4EAF1),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_month_outlined,
                        color: Color(0xFF24598B),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Trip Date & Time',
                              style: TextStyle(
                                color: Color(0xFF6D7888),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              _selectedDateTime == null
                                  ? 'Select date and time'
                                  : _formatSelectedDateTime(),
                              style: TextStyle(
                                color: _selectedDateTime == null
                                    ? const Color(0xFFA5AFBC)
                                    : const Color(0xFF354052),
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: Color(0xFF8994A3),
                      ),
                    ],
                  ),
                ),
              ),
              if (submitState.hasError) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF5F2),
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(
                      color: const Color(0xFFF3D1C9),
                    ),
                  ),
                  child: Text(
                    'Could not save trip: ${submitState.error}',
                    style: const TextStyle(
                      color: Color(0xFFB4433D),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF24598B),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFF9AA7B5),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: isLoading
                      ? const SizedBox(
                          width: 19,
                          height: 19,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check_rounded),
                  label: Text(
                    isLoading ? 'Saving Trip...' : 'Save Trip',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatSelectedDateTime() {
    final t = _selectedDateTime!;
    final hour = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final minute = t.minute.toString().padLeft(2, '0');
    final period = t.hour >= 12 ? 'PM' : 'AM';

    return '${t.day}/${t.month}/${t.year}  •  $hour:$minute $period';
  }
}
