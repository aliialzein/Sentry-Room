import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLogin = true;
  String _identifier = ''; // Used for login (username or email)
  String _username = ''; // Used for registration
  String _email = ''; // Used for registration
  String _password = '';
  String _fullName = ''; // Used for registration
  bool _isLoading = false;

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    authProvider.clearError();
    setState(() => _isLoading = true);

    bool success;
    if (_isLogin) {
      success = await authProvider.login(_identifier, _password);
    } else {
      success = await authProvider.register(
        username: _username,
        email: _email,
        password: _password,
        fullName: _fullName,
      );
    }

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (!success) {
      final errorMsg = authProvider.errorMessage ??
          'Authentication failed. Please check your credentials.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
              theme.colorScheme.surface,
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.security, size: 80, color: Colors.blueAccent),
                const SizedBox(height: 16),
                Text(
                  'Sentry Room',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 32),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_isLogin)
                            TextFormField(
                              key: const ValueKey('login_identifier'),
                              decoration: const InputDecoration(
                                labelText: 'Username or Email',
                                prefixIcon: Icon(Icons.person_outline),
                              ),
                              validator: (val) =>
                                  val!.isEmpty ? 'Enter identifier' : null,
                              onSaved: (val) => _identifier = val!,
                            )
                          else ...[
                            TextFormField(
                              key: const ValueKey('reg_fullname'),
                              decoration: const InputDecoration(
                                labelText: 'Full Name',
                                prefixIcon: Icon(Icons.badge_outlined),
                              ),
                              validator: (val) =>
                                  val!.isEmpty ? 'Enter full name' : null,
                              onSaved: (val) => _fullName = val!,
                            ),
                            TextFormField(
                              key: const ValueKey('reg_username'),
                              decoration: const InputDecoration(
                                labelText: 'Username',
                                prefixIcon: Icon(Icons.alternate_email),
                              ),
                              validator: (val) =>
                                  val!.isEmpty ? 'Enter username' : null,
                              onSaved: (val) => _username = val!,
                            ),
                            TextFormField(
                              key: const ValueKey('reg_email'),
                              decoration: const InputDecoration(
                                labelText: 'Email',
                                prefixIcon: Icon(Icons.email_outlined),
                              ),
                              keyboardType: TextInputType.emailAddress,
                              validator: (val) => !val!.contains('@')
                                  ? 'Enter valid email'
                                  : null,
                              onSaved: (val) => _email = val!,
                            ),
                          ],
                          TextFormField(
                            key: const ValueKey('password'),
                            decoration: const InputDecoration(
                              labelText: 'Password',
                              prefixIcon: Icon(Icons.lock_outline),
                            ),
                            obscureText: true,
                            validator: (val) =>
                                val!.length < 6 ? 'Password too short' : null,
                            onSaved: (val) => _password = val!,
                          ),
                          const SizedBox(height: 24),
                          if (_isLoading)
                            const CircularProgressIndicator()
                          else
                            ElevatedButton(
                              onPressed: _submit,
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size.fromHeight(50),
                                backgroundColor: Colors.blueAccent,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                              child: Text(_isLogin ? 'Login' : 'Register'),
                            ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () {
                              setState(() => _isLogin = !_isLogin);
                              context.read<AuthProvider>().clearError();
                            },
                            child: Text(_isLogin
                                ? 'Create an account'
                                : 'Already have an account? Login'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
