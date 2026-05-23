import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: person.isAuthorized
                            ? Colors.green.withValues(alpha: 0.1)
                            : Colors.red.withValues(alpha: 0.1),
                        child: Icon(
                          person.isAuthorized
                              ? Icons.verified
                              : Icons.person_off,
                          color:
                              person.isAuthorized ? Colors.green : Colors.red,
                        ),
                      ),
                      title: Text(person.fullName,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(person.role ?? 'Visitor'),
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'toggle') {
                            context
                                .read<SentryProvider>()
                                .updatePersonAuthorization(
                                  person.id,
                                  !person.isAuthorized,
                                );
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'toggle',
                            child: Text(person.isAuthorized
                                ? 'Revoke Access'
                                : 'Grant Access'),
                          ),
                          const PopupMenuItem(
                            value: 'details',
                            child: Text('View Details'),
                          ),
                        ],
                      ),
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

  void _showAddPersonDialog(BuildContext context) {
    final nameController = TextEditingController();
    final roleController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              final role = roleController.text.trim();
              if (name.isNotEmpty) {
                context
                    .read<SentryProvider>()
                    .createPerson(name, role.isEmpty ? null : role);
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
