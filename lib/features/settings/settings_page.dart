import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
              onPressed: () async {},
                
              child: Text(t.testFirestoreAccess),
            ),
          ],
        ),
      ),
    );
  }
}
