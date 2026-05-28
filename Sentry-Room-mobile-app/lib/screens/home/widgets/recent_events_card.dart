import 'package:flutter/material.dart';

import 'glass_panel.dart';
import 'panel_header.dart';

class RecentEventsCard extends StatelessWidget {
  const RecentEventsCard({
    super.key,
    required this.subtitle,
    required this.onViewAllEvents,
    required this.children,
  });

  final String subtitle;
  final VoidCallback onViewAllEvents;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PanelHeader(
            icon: Icons.history_rounded,
            title: 'Recent Events',
            subtitle: subtitle,
            trailing: TextButton(
              onPressed: onViewAllEvents,
              child: const Text('View All Events'),
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}
