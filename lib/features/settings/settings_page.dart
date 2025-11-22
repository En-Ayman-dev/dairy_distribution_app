import 'package:dairy_distribution_app/data/datasources/local/database_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'settings_notifier.dart';
import '../../l10n/app_localizations.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(settingsNotifierProvider);
    final notifier = ref.read(settingsNotifierProvider.notifier);
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(t.settingsTitle),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.languageLabel),
            const SizedBox(height: 8),
            DropdownButton<Locale?>(
              value: state.locale ?? Locale('en'),
              items: [
                DropdownMenuItem(value: Locale('en'), child: Text(t.english)),
                DropdownMenuItem(value: Locale('ar'), child: Text(t.arabic)),
              ],
              onChanged: (locale) async {
                await notifier.setLocale(locale);
              },
            ),
            const SizedBox(height: 24),
            Text(t.themeLabel),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(t.lightModeLabel),
                Switch(
                  value: state.themeMode == ThemeMode.dark,
                  onChanged: (v) async {
                    await notifier.setThemeMode(v ? ThemeMode.dark : ThemeMode.light);
                  },
                ),
                Text(t.darkModeLabel),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                final uid = FirebaseAuth.instance.currentUser?.uid;
                if (uid == null) {
                  messenger.showSnackBar(SnackBar(content: Text(t.notAuthenticated)));
                  return;
                }

                try {
                  // Attempt a small user-scoped read to validate Firestore permissions.
                  final q = FirebaseFirestore.instance
                      .collection('users')
                      .doc(uid)
                      .collection('products')
                      .limit(1);
                  final snapshot = await q.get();
                  final count = snapshot.docs.length;
                  final title = t.firestoreReadResult;
          final content = count == 0
            ? 'No documents found under users/$uid/products (read succeeded).'
            : 'Found $count document(s). First doc id: ${snapshot.docs.first.id}';

                  // show a dialog with details
                  if (!context.mounted) return;
                  showDialog<void>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Text(title),
                      content: Text(content),
                      actions: [
                        TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text(t.ok)),
                      ],
                    ),
                  );
                } on FirebaseException catch (e) {
                  // Show detailed FirebaseException info for diagnostics
                  if (!context.mounted) return;
                  showDialog<void>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Text(t.firestoreError),
                      content: SingleChildScrollView(
                        child: Text('code: ${e.code}\nmessage: ${e.message}\nstack: ${e.stackTrace}'),
                      ),
                      actions: [
                        TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text(t.ok)),
                      ],
                    ),
                  );
                } catch (e, st) {
                  if (!context.mounted) return;
                  showDialog<void>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Text(t.unexpectedError),
                      content: SingleChildScrollView(child: Text('$e\n$st')),
                      actions: [
                        TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text(t.ok)),
                      ],
                    ),
                  );
                }
              },
              child: Text(t.testFirestoreAccess),
            ),
          ],
        ),
      ),
    );
  }
}
