import 'package:flutter/material.dart';

class DashboardAction {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool isPrimary;
  final Color? customColor;

  const DashboardAction({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.isPrimary = false,
    this.customColor,
  });
}

class QuickActions extends StatelessWidget {
  final List<DashboardAction> actions;

  const QuickActions({super.key, required this.actions});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (int i = 0; i < actions.length; i++) ...[
          _ActionButton(action: actions[i]),
          if (i < actions.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final DashboardAction action;

  const _ActionButton({required this.action});

  @override
  Widget build(BuildContext context) {
    if (action.isPrimary) {
      return ElevatedButton.icon(
        onPressed: action.onPressed,
        icon: Icon(action.icon),
        label: Text(action.label),
        style: action.customColor != null
            ? ElevatedButton.styleFrom(
                backgroundColor: action.customColor,
                foregroundColor: Colors.white,
              )
            : null,
      );
    }

    return OutlinedButton.icon(
      onPressed: action.onPressed,
      icon: Icon(action.icon),
      label: Text(action.label),
      style: action.customColor != null
          ? OutlinedButton.styleFrom(
              foregroundColor: action.customColor,
              side: BorderSide(color: action.customColor!, width: 1.5),
            )
          : null,
    );
  }
}
