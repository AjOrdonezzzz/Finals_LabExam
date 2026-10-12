import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'widgets.dart';

class DetailsScreen extends StatelessWidget {
  const DetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final String id = args['id'].toString();
    final String title = args['title'] ?? '';
    final String body = args['body'] ?? '';
    final String user = (args['recommendedBy'] ?? 'anonymous').toString();
    final String image = args['image']?.toString() ?? '';
    final box = Hive.box('favoritesBox');

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
        title: const Text(
          'Recommendation',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        children: [
          // ---------- Solid navy band with the cover on top ----------
          SizedBox(
            height: 270,
            child: Stack(
              children: [
                Container(height: 150, color: kPrimary),
                Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 24),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 16,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: CoverImage(url: image, width: 150, height: 225),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ---------- Info ----------
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.w900),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GenreChip(genre: args['genre']?.toString() ?? ''),
                    const SizedBox(width: 14),
                    RatingBadge(rating: args['ratings'] as num?),
                  ],
                ),
                const SizedBox(height: 20),

                // Recommender card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F9FB),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: kBorder),
                  ),
                  child: Row(
                    children: [
                      UserAvatar(
                          url: args['avatar']?.toString(),
                          name: user,
                          radius: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('@$user',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800, fontSize: 15)),
                            const SizedBox(height: 2),
                            const Text('recommends this manhwa',
                                style: TextStyle(color: kGrey, fontSize: 13)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                const Text('Why I recommend it',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text(body, style: const TextStyle(fontSize: 16, height: 1.5)),
                const SizedBox(height: 24),

                // ---------- Save button (full width) ----------
                ValueListenableBuilder(
                  valueListenable: box.listenable(),
                  builder: (context, Box b, _) {
                    final saved = b.containsKey(id);
                    return SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton.icon(
                        icon: Icon(
                            saved ? Icons.favorite : Icons.favorite_border),
                        label: Text(
                          saved ? 'Saved to Favorites' : 'Save to Favorites',
                          style: const TextStyle(fontSize: 16),
                        ),
                        onPressed: () {
                          if (saved) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Already in favorites')),
                            );
                            return;
                          }
                          // CREATE: post id is the key, so no duplicates
                          b.put(id, postToFavorite(args));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Saved to favorites')),
                          );
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),
          Container(height: 8, color: const Color(0xFFF2F4F7)),

          // ---------- Comments (placeholder) ----------
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Text('Comments',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w900)),
                    SizedBox(width: 6),
                    Text('0',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: kPrimary)),
                  ],
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Comments coming soon')),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F7FA),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Row(
                      children: [
                        Expanded(
                          child: Text('Add a comment...',
                              style: TextStyle(color: kGrey)),
                        ),
                        Icon(Icons.send_rounded, color: kPrimary, size: 20),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                const Center(
                  child: Column(
                    children: [
                      Icon(Icons.chat_bubble_outline,
                          size: 40, color: Color(0xFFCCD3DD)),
                      SizedBox(height: 8),
                      Text('No comments yet',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                      SizedBox(height: 4),
                      Text('Be the first to share your thoughts.',
                          style: TextStyle(color: kGrey)),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
