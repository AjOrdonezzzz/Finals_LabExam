import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../app_config.dart';
import '../app_palette.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/manhwa_cover.dart';
import '../widgets/recommendation_cover.dart';
import 'posts_screen.dart';

class DiscoverScreen extends StatelessWidget {
  const DiscoverScreen({super.key});
  static const categories = [
    ('Romance', Icons.favorite_rounded, Color(0xFFEF7090)),
    ('Fantasy', Icons.auto_awesome_rounded, Color(0xFF5579D6)),
    ('Action', Icons.bolt_rounded, Color(0xFFE8963D)),
    ('Thriller', Icons.visibility_rounded, Color(0xFF7054A5)),
    ('Drama', Icons.theater_comedy_rounded, Color(0xFF39A99B)),
  ];

  @override
  Widget build(BuildContext context) {
    final box = Hive.box(recommendationsBoxName);
    return Scaffold(
      appBar: AppBar(title: const Text('Discover')),
      bottomNavigationBar: const AppBottomNav(selectedIndex: 1),
      body: ValueListenableBuilder(
        valueListenable: box.listenable(),
        builder: (context, Box recs, _) {
          final posts = recs.values.map((value) => Map<String, dynamic>.from(value as Map)).toList();
          return ListView(padding: const EdgeInsets.fromLTRB(18, 6, 18, 24), children: [
            Container(
              padding: const EdgeInsets.all(21),
              decoration: BoxDecoration(gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppPalette.darkBlue, AppPalette.blue, Color(0xFF16A4D1)]), borderRadius: BorderRadius.circular(23)),
              child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('WHAT ARE YOU IN THE MOOD FOR?', style: TextStyle(color: Color(0xFFFFD885), fontSize: 9, letterSpacing: 1.2, fontWeight: FontWeight.w900)),
                SizedBox(height: 8),
                Text('Find your next\ncan’t-put-it-down.', style: TextStyle(color: Colors.white, fontSize: 23, height: 1.1, fontWeight: FontWeight.w900)),
              ]),
            ),
            const SizedBox(height: 22),
            const Text('Browse by genre', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            Wrap(spacing: 10, runSpacing: 10, children: [
              for (final (label, icon, color) in categories)
                _GenreCard(
                  label: label,
                  icon: icon,
                  color: color,
                  count: posts.where((post) => post['genre'] == label).length,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PostsScreen(initialGenre: label))),
                ),
            ]),
            const SizedBox(height: 24),
            const Text('Reader favorites', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            for (final post in (posts..sort((a, b) => (b['likes'] as int).compareTo(a['likes'] as int))).take(5))
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Card(
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => Navigator.pushNamed(context, '/details', arguments: post),
                    child: Row(children: [
                      SizedBox(width: 104, height: 112, child: RecommendationCover(variant: post['cover'] as int, height: 112, imageUrl: post['image'] as String?)),
                      const SizedBox(width: 13),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text((post['genre'] as String).toUpperCase(), style: const TextStyle(color: AppPalette.blue, fontSize: 9, letterSpacing: 1, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 5),
                        Text(post['title'] as String, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 6),
                        Row(children: [const Icon(Icons.favorite_rounded, color: AppPalette.pink, size: 14), const SizedBox(width: 4), Text('${post['likes']} likes', style: const TextStyle(fontSize: 11, color: Color(0xFF818B9A), fontWeight: FontWeight.w700))]),
                      ])),
                      const SizedBox(width: 12),
                    ]),
                  ),
                ),
              ),
          ]);
        },
      ),
    );
  }
}

class _GenreCard extends StatelessWidget {
  const _GenreCard({required this.label, required this.icon, required this.color, required this.count, required this.onTap});
  final String label;
  final IconData icon;
  final Color color;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(18),
    child: Container(
      width: (MediaQuery.sizeOf(context).width - 46) / 2,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: .12))),
      child: Row(children: [
        Container(width: 38, height: 38, decoration: BoxDecoration(color: color.withValues(alpha: .14), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color, size: 20)),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)), Text('$count threads', style: const TextStyle(color: Color(0xFF818B9A), fontSize: 10))])),
      ]),
    ),
  );
}

