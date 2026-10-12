import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../app_config.dart';
import '../app_palette.dart';
import '../widgets/recommendation_cover.dart';
import '../services/recommendation_api.dart';

class PostDetailsScreen extends StatefulWidget {
  const PostDetailsScreen({super.key});
  @override
  State<PostDetailsScreen> createState() => _PostDetailsScreenState();
}

class _PostDetailsScreenState extends State<PostDetailsScreen> {
  double _fontSize = 18;
  final _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _addComment(Map<String, dynamic> post) async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;
    final box = Hive.box(recommendationsBoxName);
    final stored = Map<String, dynamic>.from(box.get(post['id']) as Map? ?? post);
    final comments = List<Map<String, dynamic>>.from((stored['comments'] ?? const <Map<String, dynamic>>[]) as List);
    comments.add({'author': '@you', 'text': text});
    stored['comments'] = comments;
    try {
      final remote = await RecommendationApi().updatePost(post['id'].toString(), {'comments': comments});
      stored.addAll(remote);
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Comment saved locally; server update failed.')));
    }
    await box.put(post['id'], stored);
    _commentController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final args = Map<String, dynamic>.from(ModalRoute.of(context)!.settings.arguments as Map);
    final id = args['id'];
    final title = args['title'] as String;
    final body = args['body'] as String;
    final author = (args['author'] ?? '@manhwa_reader') as String;
    final genre = (args['genre'] ?? 'Manhwa') as String;
    final cover = (args['cover'] as int?) ?? ((int.tryParse(id.toString()) ?? id.toString().hashCode.abs()) % 4);
    final box = Hive.box(favoritesBoxName);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recommendation'),
        actions: [
          IconButton(tooltip: 'Decrease text size', onPressed: () => setState(() => _fontSize = (_fontSize - 1).clamp(14, 26)), icon: const Icon(Icons.text_decrease_rounded)),
          IconButton(tooltip: 'Increase text size', onPressed: () => setState(() => _fontSize = (_fontSize + 1).clamp(14, 26)), icon: const Icon(Icons.text_increase_rounded)),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 6, 18, 28),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: SizedBox(
              height: 260,
              child: Stack(fit: StackFit.expand, children: [
                RecommendationCover(variant: cover, height: 260, imageUrl: args['image'] as String?),
                const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Color(0xD900173B)]))),
                Positioned(left: 18, right: 18, bottom: 18, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: AppPalette.pink, borderRadius: BorderRadius.circular(20)), child: Text(genre.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 9, letterSpacing: 1, fontWeight: FontWeight.w900))),
                  const SizedBox(height: 9),
                  Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 23, height: 1.1, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 6),
                  Text('recommended by $author', style: const TextStyle(color: Color(0xFFE3EEFF), fontSize: 12, fontWeight: FontWeight.w600)),
                ])),
              ]),
            ),
          ),
          const SizedBox(height: 21),
          Row(children: [
            Expanded(child: Text('WHY YOU SHOULD READ IT', style: TextStyle(color: theme.colorScheme.primary, fontSize: 10, letterSpacing: 1.4, fontWeight: FontWeight.w900))),
            Text('${(body.split(' ').length / 180).ceil().clamp(1, 4)} MIN READ', style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: .55), fontSize: 9, letterSpacing: 1, fontWeight: FontWeight.w800)),
          ]),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.fromLTRB(19, 20, 19, 20),
            decoration: BoxDecoration(color: theme.colorScheme.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: theme.dividerColor.withValues(alpha: .15))),
            child: Text(body, style: TextStyle(fontSize: _fontSize, height: 1.7, color: theme.colorScheme.onSurface, fontWeight: FontWeight.w500)),
          ),
          const SizedBox(height: 20),
          Text('READER THREAD', style: TextStyle(color: theme.colorScheme.primary, fontSize: 10, letterSpacing: 1.4, fontWeight: FontWeight.w900)),
          const SizedBox(height: 9),
          ValueListenableBuilder(
            valueListenable: Hive.box(recommendationsBoxName).listenable(keys: [id]),
            builder: (context, Box recommendations, _) {
              final savedPost = Map<String, dynamic>.from(recommendations.get(id) as Map? ?? args);
              final comments = List<Map>.from(savedPost['comments'] ?? const []);
              return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (comments.isEmpty)
                  Padding(padding: const EdgeInsets.only(bottom: 10), child: Text('Be the first to share a thought.', style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: .6), fontSize: 12))),
                for (final comment in comments)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(radius: 17, backgroundColor: theme.colorScheme.primary.withValues(alpha: .12), child: Icon(Icons.person_rounded, size: 18, color: theme.colorScheme.primary)),
                    title: Text(comment['author'] as String, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                    subtitle: Text(comment['text'] as String, style: const TextStyle(height: 1.35)),
                  ),
                Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Expanded(child: TextField(controller: _commentController, maxLines: 2, minLines: 1, decoration: const InputDecoration(hintText: 'Add to the conversation...'))),
                  const SizedBox(width: 8),
                  IconButton.filled(onPressed: () => _addComment(savedPost), tooltip: 'Post comment', icon: const Icon(Icons.send_rounded)),
                ]),
              ]);
            },
          ),
          const SizedBox(height: 17),
          ValueListenableBuilder(
            valueListenable: box.listenable(keys: [id]),
            builder: (context, Box favorites, _) {
              final saved = favorites.containsKey(id);
              return ElevatedButton.icon(
                onPressed: () async {
                  if (saved) {
                    await box.delete(id);
                  } else {
                    await box.put(id, {...args, 'note': args['note'] ?? ''});
                  }
                },
                icon: Icon(saved ? Icons.bookmark_added_rounded : Icons.bookmark_add_outlined),
                label: Text(saved ? 'Saved to your shelf' : 'Save recommendation'),
              );
            },
          ),
          const SizedBox(height: 10),
          Center(child: TextButton.icon(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back_rounded), label: const Text('Back to threads'))),
        ],
      )),
    );
  }
}







