import 'package:flutter/material.dart';
import '../services/appearance_controller.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final appearance = AppearanceScope.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Appearance', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          const Text('Choose the look that feels comfortable for you.'),
          const SizedBox(height: 20),
          Card(
            child: RadioGroup<ThemeMode>(
              groupValue: appearance.mode,
              onChanged: (mode) async {
                if (mode == null) return;
                try {
                  await appearance.setMode(mode);
                } catch (error) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('$error')));
                  }
                }
              },
              child: const Column(
                children: [
                  RadioListTile(
                    value: ThemeMode.system,
                    title: Text('Use system setting'),
                    subtitle: Text('Match your device appearance'),
                  ),
                  RadioListTile(value: ThemeMode.light, title: Text('Light')),
                  RadioListTile(value: ThemeMode.dark, title: Text('Dark')),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),
          Text('About BlockLab', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          const Text(
            'Build, experiment, and learn with 3D shapes. Your works and learning progress stay on this device.',
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () =>
                showLicensePage(context: context, applicationName: 'BlockLab'),
            child: const Text('Open-source notices'),
          ),
        ],
      ),
    );
  }
}
