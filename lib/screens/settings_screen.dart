import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../app_config.dart';
import '../app_palette.dart';
import '../widgets/app_bottom_nav.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Hive.box(settingsBoxName);
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      bottomNavigationBar: const AppBottomNav(selectedIndex: 3),
      body: ListView(padding: const EdgeInsets.fromLTRB(20, 8, 20, 24), children: [
        Container(
          padding: const EdgeInsets.all(21),
          decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppPalette.darkBlue, AppPalette.blue]), borderRadius: BorderRadius.circular(24)),
          child: const Row(children: [
            Icon(Icons.auto_stories_rounded, color: Colors.white, size: 38),
            SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Make it yours', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20)),
              SizedBox(height: 4),
              Text('Tune your reading corner.', style: TextStyle(color: Color(0xFFDCEBFF))),
            ])),
          ]),
        ),
        const SizedBox(height: 24),
        const Text('APPEARANCE', style: TextStyle(fontSize: 11, letterSpacing: 1.4, fontWeight: FontWeight.w900, color: Color(0xFF858D99))),
        const SizedBox(height: 10),
        ValueListenableBuilder(
          valueListenable: settings.listenable(keys: const ['darkMode']),
          builder: (context, Box box, _) {
            final dark = box.get('darkMode', defaultValue: false) as bool;
            return Card(
              child: SwitchListTile.adaptive(
                value: dark,
                onChanged: (value) => box.put('darkMode', value),
                secondary: Icon(dark ? Icons.dark_mode_rounded : Icons.light_mode_rounded, color: Theme.of(context).colorScheme.primary),
                title: Text(dark ? 'Dark mode' : 'Light mode', style: const TextStyle(fontWeight: FontWeight.w800)),
                subtitle: const Text('Choose a comfy look for your feed'),
              ),
            );
          },
        ),
        const SizedBox(height: 24),
        const Text('YOUR COMMUNITY', style: TextStyle(fontSize: 11, letterSpacing: 1.4, fontWeight: FontWeight.w900, color: Color(0xFF858D99))),
        const SizedBox(height: 10),
        Card(child: ListTile(
          leading: Icon(Icons.bookmark_added_outlined, color: Theme.of(context).colorScheme.primary),
          title: const Text('Saved recommendations', style: TextStyle(fontWeight: FontWeight.w800)),
          subtitle: const Text('Keep the stories you want to read'),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => Navigator.pushNamed(context, '/favorites'),
        )),
        const SizedBox(height: 10),
        Card(child: const ListTile(
          leading: Icon(Icons.forum_outlined),
          title: Text('Manhwa Threads', style: TextStyle(fontWeight: FontWeight.w800)),
          subtitle: Text('A cozy corner to share your next favorite read.'),
        )),
      ]),
    );
  }
}


