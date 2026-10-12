import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'widgets.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  // UPDATE: edit the personal note
  Future<void> editNote(BuildContext context, Map fav) async {
    final controller = TextEditingController(text: fav['note'] ?? '');

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Personal Note'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
              hintText: 'e.g. Read after finishing Solo Leveling'),
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
      final box = Hive.box('favoritesBox');
      box.put(fav['id'], {...fav, 'note': controller.text.trim()});
    }
    controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final box = Hive.box('favoritesBox');

    return Scaffold(
      appBar: AppBar(title: const Text('My Favorites')),
      body: ValueListenableBuilder(
        valueListenable: box.listenable(),
        builder: (context, Box box, _) {
          if (box.isEmpty) {
            return const Center(child: Text('No favorites yet'));
          }

          // READ: all saved posts
          final favorites = box.values.toList();

          return ListView.separated(
            itemCount: favorites.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final fav = Map<dynamic, dynamic>.from(favorites[index]);
              final note = (fav['note'] ?? '') as String;
              final user = (fav['recommendedBy'] ?? 'anonymous').toString();

              return ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: CoverImage(
                    url: fav['image']?.toString(), width: 50, height: 75),
                title: Text(
                  fav['title'] ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        UserAvatar(
                            url: fav['avatar']?.toString(),
                            name: user,
                            radius: 9),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text('@$user',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    RatingBadge(rating: fav['ratings'] as num?),
                    const SizedBox(height: 6),
                    Text(
                      note.isEmpty ? 'No note yet' : 'Note: $note',
                      style: TextStyle(
                        fontStyle:
                            note.isEmpty ? FontStyle.italic : FontStyle.normal,
                      ),
                    ),
                  ],
                ),
                isThreeLine: true,
                onTap: () => editNote(context, fav),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      tooltip: 'Edit note',
                      onPressed: () => editNote(context, fav),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      tooltip: 'Delete',
                      // DELETE
                      onPressed: () => box.delete(fav['id']),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
