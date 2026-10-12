import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../main.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  Future<void> _editNote(BuildContext context, Box box, Map post) async {
    final controller = TextEditingController(text: post['note'] ?? '');
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Personal note'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(hintText: 'Write a short note...'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (saved == true) {
      // Part 3 (Update): write the changed map back using the same key.
      final updated = Map<String, dynamic>.from(post);
      updated['note'] = controller.text.trim();
      await box.put(post['id'], updated);
    }
  }

  @override
  Widget build(BuildContext context) {
    final box = Hive.box(favoritesBoxName);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorites'),
        leading: BackButton(onPressed: () => Navigator.pop(context)),
      ),
      // Part 3 (Read): rebuild automatically whenever the box changes.
      body: ValueListenableBuilder(
        valueListenable: box.listenable(),
        builder: (context, Box box, _) {
          final favorites = box.values.toList();
          if (favorites.isEmpty) {
            return const Center(child: Text('No favorites yet'));
          }
          return ListView.builder(
            itemCount: favorites.length,
            itemBuilder: (context, index) {
              final post = Map<String, dynamic>.from(favorites[index] as Map);
              final note = (post['note'] ?? '') as String;
              return Dismissible(
                key: ValueKey(post['id']),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 16),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                // Part 3 (Delete): swipe to remove.
                onDismissed: (_) => box.delete(post['id']),
                child: ListTile(
                  title: Text(post['title'],
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(
                    note.isEmpty ? post['body'] : 'Note: $note',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_note),
                        tooltip: 'Edit note',
                        onPressed: () => _editNote(context, box, post),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        tooltip: 'Remove',
                        onPressed: () => box.delete(post['id']),
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
