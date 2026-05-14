import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sentry_room_mobile/main.dart';
import 'package:sentry_room_mobile/providers/auth_provider.dart';
import 'package:sentry_room_mobile/providers/sentry_provider.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    // Wrap the app with the same providers used in main.dart
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => SentryProvider()),
        ],
        child: const SentryRoomApp(),
      ),
    );

    // Verify that the login screen (AuthScreen) is shown initially.
    expect(find.text('Sentry Room'), findsAtLeastNWidgets(1));
    expect(find.text('Login'), findsOneWidget);
    
    // Verify that we have input fields for username and password.
    expect(find.byType(TextFormField), findsAtLeastNWidgets(2));
  });
}
