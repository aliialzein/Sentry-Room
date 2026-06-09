import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../constants/api_constants.dart';
import '../models/sentry_models.dart';
import '../providers/sentry_provider.dart';

class PeopleScreen extends StatelessWidget {
  const PeopleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sentry = context.watch<SentryProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recognized Persons'),
      ),
      body: RefreshIndicator(
        onRefresh: sentry.refreshData,
        child: sentry.isLoading && sentry.persons.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: sentry.persons.length,
                itemBuilder: (context, index) {
                  final person = sentry.persons[index];
                  final lastEvent = _lastEventForPerson(sentry.events, person);
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ExpansionTile(
                      leading: _buildPersonAvatar(person),
                      title: Text(person.fullName,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(_personSubtitle(person, lastEvent)),
                      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      children: [
                        _buildPersonImage(person),
                        const SizedBox(height: 12),
                        _buildDetailRow('Role', person.role ?? 'Visitor'),
                        _buildDetailRow(
                          'Access',
                          person.isAuthorized ? 'Authorized' : 'Unauthorized',
                        ),
                        _buildDetailRow(
                          'Last seen',
                          lastEvent == null
                              ? 'No linked event yet'
                              : _formatTimestamp(
                                  lastEvent.lastSeenAt ?? lastEvent.createdAt,
                                ),
                        ),
                        if (lastEvent != null)
                          _buildDetailRow('Last event', lastEvent.message),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              context
                                  .read<SentryProvider>()
                                  .updatePersonAuthorization(
                                    person.id,
                                    !person.isAuthorized,
                                  );
                            },
                            icon: Icon(person.isAuthorized
                                ? Icons.person_off_outlined
                                : Icons.verified_outlined),
                            label: Text(person.isAuthorized
                                ? 'Revoke Access'
                                : 'Grant Access'),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddPersonDialog(context),
        child: const Icon(Icons.person_add),
      ),
    );
  }

  Widget _buildPersonAvatar(Person person) {
    final imagePath = person.imagePath;
    final color = person.isAuthorized ? Colors.green : Colors.red;

    return CircleAvatar(
      backgroundColor: color.withValues(alpha: 0.1),
      backgroundImage: imagePath == null
          ? null
          : NetworkImage(ApiConstants.snapshotUrl(imagePath)),
      child: imagePath != null
          ? null
          : Icon(
              person.isAuthorized ? Icons.verified : Icons.person_off,
              color: color,
            ),
    );
  }

  Widget _buildPersonImage(Person person) {
    final imagePath = person.imagePath;
    if (imagePath == null) {
      return Container(
        height: 160,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.black12,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text('No enrollment image'),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Image.network(
          ApiConstants.snapshotUrl(imagePath),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            color: Colors.black12,
            alignment: Alignment.center,
            child: const Text('Image unavailable'),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 84,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Event? _lastEventForPerson(List<Event> events, Person person) {
    for (final event in events) {
      if (event.personId == person.id) {
        return event;
      }
    }
    return null;
  }

  String _personSubtitle(Person person, Event? lastEvent) {
    final access = person.isAuthorized ? 'Authorized' : 'Unauthorized';
    if (lastEvent == null) {
      return '${person.role ?? 'Visitor'} - $access';
    }
    return '${person.role ?? 'Visitor'} - $access - Seen ${_formatTimestamp(lastEvent.lastSeenAt ?? lastEvent.createdAt)}';
  }

  String _formatTimestamp(DateTime value) {
    return DateFormat('MMM dd, HH:mm').format(value);
  }

  void _showAddPersonDialog(BuildContext context) {
    final parentContext = context;
    final nameController = TextEditingController();
    final roleController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add Authorized Person'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Full Name'),
            ),
            TextField(
              controller: roleController,
              decoration: const InputDecoration(
                  labelText: 'Role (e.g. Employee, Admin)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton.icon(
            onPressed: () async {
              final name = nameController.text.trim();
              final role = roleController.text.trim();
              if (name.isNotEmpty) {
                final success = await parentContext
                    .read<SentryProvider>()
                    .createPerson(name, role.isEmpty ? null : role);
                if (!parentContext.mounted) return;
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(parentContext).showSnackBar(
                  SnackBar(
                    content: Text(success
                        ? 'Person saved.'
                        : (parentContext.read<SentryProvider>().lastActionError ??
                            'Failed to save person.')),
                  ),
                );
              }
            },
            icon: const Icon(Icons.save_outlined),
            label: const Text('Save Record'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              final name = nameController.text.trim();
              final role = roleController.text.trim();
              if (name.isNotEmpty) {
                final success = await parentContext
                    .read<SentryProvider>()
                    .enrollPersonFromCamera(name, role.isEmpty ? null : role);
                if (!parentContext.mounted) return;
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(parentContext).showSnackBar(
                  SnackBar(
                    content: Text(success
                        ? 'Person enrolled from camera.'
                        : (parentContext.read<SentryProvider>().lastActionError ??
                            'Failed to enroll person.')),
                  ),
                );
              }
            },
            icon: const Icon(Icons.camera_alt_outlined),
            label: const Text('Enroll'),
          ),
        ],
      ),
    );
  }
}
