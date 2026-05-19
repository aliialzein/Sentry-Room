import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  late Future<List<Map<String, dynamic>>> _usersFuture;

  @override
  void initState() {
    super.initState();
    _refreshUsers();
  }

  void _refreshUsers() {
    setState(() {
      _usersFuture = context.read<AuthProvider>().fetchAllUsers();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshUsers,
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _usersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final users = snapshot.data ?? [];
          if (users.isEmpty) {
            return const Center(child: Text('No users found.'));
          }

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              final int userId = user['id'];
              final String username = user['username'];
              final String fullName = user['full_name'] ?? 'N/A';
              final String role = user['role'] ?? 'viewer';
              final bool isActive = user['is_active'] ?? true;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(fullName),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Username: $username'),
                      Text('Role: ${role.toUpperCase()}'),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.edit_note),
                        tooltip: 'Change Role',
                        onSelected: (newRole) async {
                          final success = await context
                              .read<AuthProvider>()
                              .updateUserRole(userId, newRole);
                          if (!context.mounted) return;
                          if (success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content:
                                      Text('Updated $username to $newRole')),
                            );
                            _refreshUsers();
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                              value: 'viewer', child: Text('Viewer')),
                          const PopupMenuItem(
                              value: 'security', child: Text('Security')),
                          const PopupMenuItem(
                              value: 'admin', child: Text('Admin')),
                        ],
                      ),
                      Switch(
                        value: isActive,
                        onChanged: (value) async {
                          final success = await context
                              .read<AuthProvider>()
                              .updateUserStatus(userId, value);
                          if (success) {
                            _refreshUsers();
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
