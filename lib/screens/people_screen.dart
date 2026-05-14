import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/sentry_provider.dart';
import '../models/sentry_models.dart';

class PeopleScreen extends StatelessWidget {
  const PeopleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sentry = context.watch<SentryProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Access Management'),
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
                            ? Colors.green.withOpacity(0.1)
                            : Colors.red.withOpacity(0.1),
                        child: Icon(
                          person.isAuthorized ? Icons.verified : Icons.person_off,
                          color: person.isAuthorized ? Colors.green : Colors.red,
                        ),
                      ),
                      title: Text(person.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(person.role ?? 'Visitor'),
                      trailing: PopupMenuButton(
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            child: Text(person.isAuthorized ? 'Revoke Access' : 'Grant Access'),
                            onTap: () {
                              // Logic to toggle authorization
                            },
                          ),
                          const PopupMenuItem(
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
    // Dialog to add a new person (placeholder)
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Authorized Person'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(decoration: InputDecoration(labelText: 'Full Name')),
            TextField(decoration: InputDecoration(labelText: 'Role')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Save')),
        ],
      ),
    );
  }
}
