import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../main.dart';

class PostDetailsScreen extends StatelessWidget {
  const PostDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Part 1: retrieve the arguments passed from the Posts screen.
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final int id = args['id'] as int;
    final String title = args['title'] as String;
    final String body = args['body'] as String;

    return Scaffold(
      appBar: AppBar(title: Text('Post #$id')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            Text(body, style: Theme.of(context).textTheme.bodyLarge),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.favorite),
                label: const Text('Save to Favorites'),
                onPressed: () {
                  final box = Hive.box(favoritesBoxName);
                  String message;
                  // Part 3 (Create): id is the key, so no duplicates.
                  if (box.containsKey(id)) {
                    message = 'Already in favorites';
                  } else {
                    box.put(id, {
                      'id': id,
                      'title': title,
                      'body': body,
                      'note': '',
                    });
                    message = 'Saved to favorites';
                  }
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text(message)));
                },
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Back'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
