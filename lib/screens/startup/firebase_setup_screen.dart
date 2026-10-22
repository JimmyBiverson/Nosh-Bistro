import 'package:flutter/material.dart';

import '../../theme/nosh_theme.dart';

class FirebaseSetupScreen extends StatelessWidget {
  const FirebaseSetupScreen({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 56,
                    width: 56,
                    decoration: BoxDecoration(
                      color: NoshTheme.primary.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(
                      Icons.local_fire_department_rounded,
                      color: NoshTheme.primary,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Nosh Bistro',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'One setup step before the app can open',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: NoshTheme.primarySoft,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    message,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: NoshTheme.muted),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: NoshTheme.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: NoshTheme.outline),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'From the project folder, run:',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        SizedBox(height: 12),
                        SelectableText(
                          'flutterfire configure',
                          style: TextStyle(
                            color: NoshTheme.primarySoft,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Select your Firebase project and platforms to '
                          'regenerate the platform options. Firebase is '
                          'initialized from the generated options in '
                          'main.dart. Restart the app with `flutter run` '
                          'when configuration is complete.',
                          style: TextStyle(color: NoshTheme.muted, height: 1.5),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'This screen replaces the blank startup when Firebase '
                    'configuration is missing. No sign-in or order data was '
                    'loaded.',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: NoshTheme.muted),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
