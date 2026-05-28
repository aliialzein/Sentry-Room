import 'package:flutter/material.dart';

class ConfirmModal extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final Color color;

  const ConfirmModal({
    super.key,
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: Icon(Icons.warning_amber_rounded, color: color, size: 42),
      title: Text(title, textAlign: TextAlign.center),
      content: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white70, height: 1.35),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: () => Navigator.of(context).pop(true),
          icon: const Icon(Icons.check_rounded),
          label: Text(confirmLabel),
          style: FilledButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.black,
          ),
        ),
      ],
    );
  }
}
