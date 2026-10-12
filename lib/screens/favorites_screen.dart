import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../app_config.dart';
import '../app_palette.dart';
import '../widgets/app_bottom_nav.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  Future<void> _editNote(BuildContext context, Box box, Map post) async {
    final controller = TextEditingController(text: post['note'] ?? '');
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reading note'),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: const InputDecoration(hintText: 'Save a thought about this chapter...'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Save note')),
        ],
      ),
    );
    if (saved == true) {
      final updated = Map<String, dynamic>.from(post)..['note'] = controller.text.trim();
      await box.put(post['id'], updated);
    }
    controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final box = Hive.box(favoritesBoxName);
    return Scaffold(
      appBar: AppBar(title: const Text('My bookmarks')),
      bottomNavigationBar: const AppBottomNav(selectedIndex: 2),
      body: ValueListenableBuilder(
        valueListenable: box.listenable(),
        builder: (context, Box favoritesBox, _) {
          final favorites = favoritesBox.values.toList();
          if (favorites.isEmpty) {
            return Center(child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 84, height: 84, decoration: BoxDecoration(color: const Color(0xFFF3E8E4), borderRadius: BorderRadius.circular(26)), child: const Icon(Icons.bookmarks_outlined, size: 38, color: AppPalette.accent)),
                const SizedBox(height: 18),
                const Text('Your shelf is waiting', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                const Text('Bookmark a chapter and it will be saved here for later.', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF77747C), height: 1.4)),
              ]),
            ));
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              Container(
                margin: const EdgeInsets.only(bottom: 18),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(color: AppPalette.ink, borderRadius: BorderRadius.circular(20)),
                child: Row(children: [
                  const Icon(Icons.auto_stories_rounded, color: Color(0xFFE6B45F), size: 30),
                  const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${favorites.length} saved ${favorites.length == 1 ? 'chapter' : 'chapters'}', style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 3),
                    const Text('Your personal reading shelf', style: TextStyle(color: Color(0xFFC9C5CD), fontSize: 12)),
                  ])),
                ]),
              ),
              for (final value in favorites)
                _FavoriteCard(
                  post: Map<String, dynamic>.from(value as Map),
                  onOpen: () => Navigator.pushNamed(context, '/details', arguments: value),
                  onEdit: () => _editNote(context, favoritesBox, Map<String, dynamic>.from(value)),
                  onDelete: () => favoritesBox.delete(value['id']),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _FavoriteCard extends StatelessWidget {
  const _FavoriteCard({required this.post, required this.onOpen, required this.onEdit, required this.onDelete});
  final Map<String, dynamic> post;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final id = post['id'];
    final note = (post['note'] ?? '') as String;
    return Dismissible(
      key: ValueKey(id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.only(right: 20),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(color: AppPalette.accent, borderRadius: BorderRadius.circular(20)),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      onDismissed: (_) => onDelete(),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: .15))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          InkWell(
            onTap: onOpen,
            borderRadius: BorderRadius.circular(12),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(width: 42, height: 54, alignment: Alignment.center, decoration: BoxDecoration(color: const Color(0xFFF3E8E4), borderRadius: BorderRadius.circular(11)), child: Text(id.toString().padLeft(2, '0'), style: const TextStyle(color: AppPalette.accent, fontWeight: FontWeight.w900))),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('CHAPTER $id', style: const TextStyle(color: AppPalette.accent, fontSize: 9, letterSpacing: 1.2, fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(post['title'] as String, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                const SizedBox(height: 4),
                Text(post['body'] as String, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF77747C), fontSize: 12, height: 1.3)),
              ])),
              IconButton(onPressed: onDelete, tooltip: 'Remove bookmark', icon: const Icon(Icons.bookmark_remove_outlined, color: AppPalette.accent)),
            ]),
          ),
          if (note.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(width: double.infinity, padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFFF7F5F0), borderRadius: BorderRadius.circular(12)), child: Text(note, style: const TextStyle(color: Color(0xFF65616A), fontSize: 12, height: 1.35))),
          ],
          Align(alignment: Alignment.centerRight, child: TextButton.icon(onPressed: onEdit, icon: const Icon(Icons.edit_note_rounded, size: 18), label: Text(note.isEmpty ? 'Add note' : 'Edit note'))),
        ]),
      ),
    );
  }
}







