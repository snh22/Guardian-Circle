import 'package:flutter/material.dart';

class QuickActionsRow extends StatelessWidget {
  final VoidCallback onViewMap;
  final VoidCallback onCall;
  final VoidCallback onAcknowledge;
  final bool acknowledgeEnabled;

  const QuickActionsRow({
    super.key,
    required this.onViewMap,
    required this.onCall,
    required this.onAcknowledge,
    this.acknowledgeEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onViewMap,
            icon: const Icon(Icons.map_outlined),
            label: const Text('View Map'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: onCall,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E8E5A),
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.call_rounded),
            label: const Text('Call'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: acknowledgeEnabled ? onAcknowledge : null,
            icon: const Icon(Icons.check_rounded),
            label: const Text('Acknowledge'),
          ),
        ),
      ],
    );
  }
}