import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../app_config.dart';
import '../app_palette.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/manhwa_cover.dart';
import '../widgets/recommendation_cover.dart';
import '../services/recommendation_api.dart';

class PostsScreen extends StatefulWidget {
  const PostsScreen({super.key, this.initialGenre = 'All'});
  final String initialGenre;
  @override
  State<PostsScreen> createState() => _PostsScreenState();
}

class _PostsScreenState extends State<PostsScreen> {
  String _genre = 'All';
  String _query = '';
  final _search = TextEditingController();
  final _api = RecommendationApi();
  bool _apiAvailable = false;
  String? _apiError;
  @override
  void initState() {
    super.initState();
    _genre = widget.initialGenre;
    _syncWithApi();
  }

  Map<String, dynamic> _normalizePost(Map<String, dynamic> raw, {int index = 0}) {
    final id = (raw['id'] ?? DateTime.now().microsecondsSinceEpoch).toString();
    final number = int.tryParse(id) ?? id.hashCode.abs();
    return {
      ...raw,
      'id': id,
      'title': (raw['title'] ?? raw['name'] ?? 'Untitled manhwa').toString(),
      'body': (raw['body'] ?? raw['description'] ?? '').toString(),
      'genre': (raw['genre'] ?? 'Manhwa').toString(),
      'author': (raw['recommendedBy'] ?? raw['author'] ?? raw['username'] ?? 'anonymous').toString(),
      'image': (raw['image'] ?? raw['coverImage'] ?? '').toString(),
      'cover': int.tryParse('${raw['cover']}') ?? number % 4,
      'ratings': double.tryParse('${raw['ratings'] ?? raw['rating'] ?? 0}') ?? 0.0,
      'likes': int.tryParse('${raw['likes'] ?? 0}') ?? 0,
      'liked': raw['liked'] == true,
      'comments': raw['comments'] is List ? raw['comments'] : <Map<String, dynamic>>[],
      'createdAt': int.tryParse('${raw['createdAt']}') ?? (DateTime.now().millisecondsSinceEpoch - index),
    };
  }

  Future<void> _syncWithApi() async {
    try {
      final posts = await _api.fetchPosts();
      final box = Hive.box(recommendationsBoxName);
      await box.clear();
      for (var i = 0; i < posts.length; i++) {
        final post = _normalizePost(posts[i], index: i);
        await box.put(post['id'], post);
      }
      if (mounted) setState(() => _apiError = null);
    } catch (error) {
      if (mounted) setState(() => _apiError = 'Showing saved recommendations. API is unavailable.');
    }
  }
  static const genres = ['All', 'Romance', 'Fantasy', 'Action', 'Thriller', 'Drama', 'Supernatural', 'Comedy'];

  @override
  void dispose() { _search.dispose(); super.dispose(); }

  Future<void> _createRecommendation(Box box) async {
    final formKey = GlobalKey<FormState>();
    final title = TextEditingController();
    final synopsis = TextEditingController();
    final author = TextEditingController();
    final image = TextEditingController();
    var genre = 'Fantasy';
    final created = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(builder: (context, setDialogState) => AlertDialog(
        title: const Text('Share a recommendation'),
        content: SingleChildScrollView(child: Form(
          key: formKey,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextFormField(controller: title, decoration: const InputDecoration(labelText: 'Manhwa title'), validator: (v) => v == null || v.trim().isEmpty ? 'Add a title' : null),
            const SizedBox(height: 12),
            TextFormField(controller: image, keyboardType: TextInputType.url, decoration: const InputDecoration(labelText: 'Cover image URL (optional)')),
            const SizedBox(height: 12),
            TextFormField(controller: author, decoration: const InputDecoration(labelText: 'Your reader name'), validator: (v) => v == null || v.trim().isEmpty ? 'Add a name' : null),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(value: genre, decoration: const InputDecoration(labelText: 'Genre'), items: genres.skip(1).map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(), onChanged: (value) { if (value != null) setDialogState(() => genre = value); }),
            const SizedBox(height: 12),
            TextFormField(controller: synopsis, maxLines: 3, decoration: const InputDecoration(labelText: 'Why should we read it?', alignLabelWithHint: true), validator: (v) => v == null || v.trim().isEmpty ? 'Write a short recommendation' : null),
            const SizedBox(height: 8),
            const Text('We�ll create an original illustrated cover for your post.', style: TextStyle(fontSize: 12, color: Color(0xFF858D99))),
          ]),
        )),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          ElevatedButton.icon(onPressed: () { if (formKey.currentState!.validate()) Navigator.pop(dialogContext, true); }, icon: const Icon(Icons.send_rounded), label: const Text('Share')),
        ],
      )),
    );
    if (created == true) {
      final authorName = author.text.trim().startsWith('@') ? author.text.trim() : '@${author.text.trim()}';
      final payload = {
        'title': title.text.trim(),
        'body': synopsis.text.trim(),
        'image': image.text.trim(),
        'ratings': 0,
        'genre': genre,
        'recommendedBy': authorName,
        'likes': 0,
        'liked': false,
        'comments': <Map<String, String>>[],
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      };
      try {
        final remote = _normalizePost(await _api.createPost(payload));
        await box.put(remote['id'], remote);
        _apiAvailable = true;
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Your recommendation was posted to MockAPI.')));
      } catch (_) {
        final id = 'local-${DateTime.now().microsecondsSinceEpoch}';
        final local = _normalizePost({...payload, 'id': id, 'author': authorName, 'cover': id.hashCode.abs() % 4});
        await box.put(id, local);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('API unavailable. Saved on this device only.')));
      }
    }
    title.dispose(); synopsis.dispose(); author.dispose(); image.dispose();
  }

  Future<void> _toggleLike(Box box, Map<String, dynamic> post) async {
    final updated = Map<String, dynamic>.from(post);
    final liked = (updated['liked'] ?? false) as bool;
    updated['liked'] = !liked;
    updated['likes'] = ((updated['likes'] ?? 0) as int) + (liked ? -1 : 1);
    try {
      final remote = await _api.updatePost(updated['id'].toString(), {'likes': updated['likes'], 'liked': updated['liked']});
      updated.addAll(_normalizePost(remote));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Like saved locally; server update failed.')));
    }
    await box.put(updated['id'], updated);
  }

  Future<void> _toggleBookmark(Box box, Map<String, dynamic> post) async {
    final bookmarks = Hive.box(favoritesBoxName);
    final id = post['id'];
    if (bookmarks.containsKey(id)) {
      await bookmarks.delete(id);
    } else {
      await bookmarks.put(id, {...post, 'note': ''});
    }
  }

  void _open(Map<String, dynamic> post) => Navigator.pushNamed(context, '/details', arguments: post);

  @override
  Widget build(BuildContext context) {
    final feed = Hive.box(recommendationsBoxName);
    final bookmarks = Hive.box(favoritesBoxName);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted = isDark ? const Color(0xFFAAB6C6) : const Color(0xFF788596);
    return Scaffold(
      appBar: AppBar(
        title: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('THREADS', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: -1)),
          Text('MANHWA REC CLUB', style: TextStyle(fontSize: 9, letterSpacing: 1.8, fontWeight: FontWeight.w800, color: Color(0xFF788596))),
        ]),
        actions: [
          IconButton(tooltip: 'Settings', onPressed: () => Navigator.pushNamed(context, '/settings'), icon: const Icon(Icons.tune_rounded)),
          const SizedBox(width: 6),
        ],
      ),
      bottomNavigationBar: const AppBottomNav(selectedIndex: 0),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createRecommendation(feed),
        backgroundColor: AppPalette.pink,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Post a rec', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: ValueListenableBuilder(
        valueListenable: feed.listenable(),
        builder: (context, Box postsBox, _) {
          final posts = postsBox.values.map((p) => Map<String, dynamic>.from(p as Map)).toList()
            ..sort((a, b) => (b['createdAt'] as int).compareTo(a['createdAt'] as int));
          final filtered = posts.where((post) {
            final queryMatch = '${post['title']} ${post['body']} ${post['author']}'.toLowerCase().contains(_query);
            return queryMatch && (_genre == 'All' || post['genre'] == _genre);
          }).toList();
          return RefreshIndicator(
            onRefresh: _syncWithApi,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(18, 5, 18, 105),
              children: [
                _WelcomeBanner(count: posts.length),
                if (_apiError != null)
                  Padding(padding: const EdgeInsets.only(top: 10), child: Text(_apiError!, style: TextStyle(color: textMuted, fontSize: 11))),
                const SizedBox(height: 20),
                SizedBox(
                  height: 44,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: genres.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final item = genres[index];
                      return ChoiceChip(
                        label: Text(item),
                        selected: _genre == item,
                        onSelected: (_) => setState(() => _genre = item),
                        selectedColor: AppPalette.blue,
                        backgroundColor: Theme.of(context).colorScheme.surface,
                        labelStyle: TextStyle(fontWeight: FontWeight.w700, color: _genre == item ? Colors.white : null),
                        side: BorderSide.none,
                        shape: const StadiumBorder(),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: _search,
                  onChanged: (value) => setState(() => _query = value.trim().toLowerCase()),
                  decoration: InputDecoration(
                    hintText: 'Find your next favorite',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _query.isEmpty ? null : IconButton(icon: const Icon(Icons.close), onPressed: () { _search.clear(); setState(() => _query = ''); }),
                  ),
                ),
                const SizedBox(height: 22),
                Row(children: [
                  const Expanded(child: Text('Featured thread', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -.4))),
                  Text('SEE ALL ${posts.length}', style: TextStyle(fontSize: 9, letterSpacing: 1.2, fontWeight: FontWeight.w900, color: textMuted)),
                ]),
                const SizedBox(height: 12),
                if (filtered.isNotEmpty && _query.isEmpty && _genre == 'All')
                  _FeaturedThread(post: filtered.first, onOpen: () => _open(filtered.first), onLike: () => _toggleLike(postsBox, filtered.first)),
                const SizedBox(height: 22),
                Row(children: [
                  const Expanded(child: Text('Fresh from the community', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900, letterSpacing: -.4))),
                  Text('${filtered.length} THREADS', style: TextStyle(fontSize: 9, letterSpacing: 1, fontWeight: FontWeight.w800, color: textMuted)),
                ]),
                const SizedBox(height: 12),
                if (filtered.isEmpty)
                  Padding(padding: const EdgeInsets.symmetric(vertical: 36), child: Center(child: Text('No threads found. Try another genre or search.', textAlign: TextAlign.center, style: TextStyle(color: textMuted))))
                else
                  for (var i = 0; i < filtered.length; i++)
                    _ThreadCard(
                      post: filtered[i],
                      bookmarked: bookmarks.containsKey(filtered[i]['id']),
                      onOpen: () => _open(filtered[i]),
                      onLike: () => _toggleLike(postsBox, filtered[i]),
                      onBookmark: () => _toggleBookmark(bookmarks, filtered[i]),
                    ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _WelcomeBanner extends StatelessWidget {
  const _WelcomeBanner({required this.count});
  final int count;
  @override
  Widget build(BuildContext context) => Container(
    height: 174,
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppPalette.darkBlue, AppPalette.blue, Color(0xFF12A4D8)]), borderRadius: BorderRadius.circular(24)),
    child: Stack(children: [
      Positioned(right: -3, bottom: 0, width: 166, height: 174, child: ClipRRect(borderRadius: const BorderRadius.only(topRight: Radius.circular(24), bottomRight: Radius.circular(24)), child: const ManhwaCover(variant: 0, height: 174))),
      Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(colors: [AppPalette.darkBlue.withOpacity(.96), AppPalette.blue.withOpacity(.72), Colors.transparent], stops: const [0, .48, 1])))),
      Padding(padding: const EdgeInsets.all(21), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('HAPPY READING!', style: TextStyle(color: Color(0xFFFFD885), fontSize: 10, letterSpacing: 1.6, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        const SizedBox(width: 190, child: Text('Your next favorite\nstarts in a thread.', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 22, height: 1.08))),
        const Spacer(),
        Text('$count recommendations from readers', style: const TextStyle(color: Color(0xFFE3EEFF), fontSize: 11, fontWeight: FontWeight.w600)),
      ])),
    ]),
  );
}

class _FeaturedThread extends StatelessWidget {
  const _FeaturedThread({required this.post, required this.onOpen, required this.onLike});
  final Map<String, dynamic> post;
  final VoidCallback onOpen;
  final VoidCallback onLike;
  @override
  Widget build(BuildContext context) => Material(
    color: Theme.of(context).colorScheme.surface,
    borderRadius: BorderRadius.circular(22),
    clipBehavior: Clip.antiAlias,
    child: InkWell(onTap: onOpen, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Stack(children: [
        SizedBox(height: 195, width: double.infinity, child: RecommendationCover(variant: post['cover'] as int, height: 195, imageUrl: post['image'] as String?)),
        Positioned(left: 13, top: 13, child: Container(padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6), decoration: BoxDecoration(color: Colors.white.withOpacity(.95), borderRadius: BorderRadius.circular(20)), child: Text((post['genre'] as String).toUpperCase(), style: const TextStyle(color: AppPalette.blue, fontSize: 9, letterSpacing: .8, fontWeight: FontWeight.w900)))),
        Positioned(right: 13, bottom: 13, child: Material(color: AppPalette.pink, shape: const CircleBorder(), child: InkWell(onTap: onOpen, customBorder: const CircleBorder(), child: const Padding(padding: EdgeInsets.all(12), child: Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 19))))),
      ]),
      Padding(padding: const EdgeInsets.fromLTRB(17, 14, 14, 14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Expanded(child: Text(post['title'] as String, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900))), Text(post['author'] as String, style: const TextStyle(fontSize: 11, color: Color(0xFF818B9A), fontWeight: FontWeight.w700))]),
        const SizedBox(height: 6),
        Text(post['body'] as String, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, height: 1.4, color: Color(0xFF788596))),
        const SizedBox(height: 10),
        Row(children: [InkWell(onTap: onLike, child: Row(children: [const Icon(Icons.favorite_rounded, color: AppPalette.pink, size: 17), const SizedBox(width: 5), Text('${post['likes']}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12))])), const SizedBox(width: 13), const Icon(Icons.star_rounded, size: 16, color: Color(0xFFFFB547)), const SizedBox(width: 3), Text('${post['ratings']}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800)), const SizedBox(width: 12), const Icon(Icons.chat_bubble_outline_rounded, size: 15, color: Color(0xFF818B9A)), const SizedBox(width: 5), const Text('Join the thread', style: TextStyle(color: Color(0xFF818B9A), fontSize: 11))]),
      ])),
    ])),
  );
}

class _ThreadCard extends StatelessWidget {
  const _ThreadCard({required this.post, required this.bookmarked, required this.onOpen, required this.onLike, required this.onBookmark});
  final Map<String, dynamic> post;
  final bool bookmarked;
  final VoidCallback onOpen;
  final VoidCallback onLike;
  final VoidCallback onBookmark;
  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    margin: const EdgeInsets.only(bottom: 12),
    child: InkWell(onTap: onOpen, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Padding(padding: const EdgeInsets.fromLTRB(14, 13, 9, 9), child: _ReaderAvatar(author: post['author'] as String, imageUrl: post['avatar'] as String?)),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(post['author'] as String, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)), Text('recommended a ${post['genre'].toString().toLowerCase()} read', style: const TextStyle(fontSize: 10, color: Color(0xFF8994A4)))])),
        IconButton(tooltip: bookmarked ? 'Remove from shelf' : 'Save to shelf', onPressed: onBookmark, icon: Icon(bookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded, color: bookmarked ? AppPalette.blue : const Color(0xFF8994A4))),
      ]),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 13), child: ClipRRect(borderRadius: BorderRadius.circular(16), child: Stack(children: [
        SizedBox(height: 148, width: double.infinity, child: RecommendationCover(variant: post['cover'] as int, height: 148, imageUrl: post['image'] as String?)),
        Positioned(left: 10, top: 10, child: Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5), decoration: BoxDecoration(color: Colors.black.withOpacity(.48), borderRadius: BorderRadius.circular(14)), child: Text((post['genre'] as String).toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 9, letterSpacing: .7, fontWeight: FontWeight.w900)))),
      ]))),
      Padding(padding: const EdgeInsets.fromLTRB(15, 12, 15, 13), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(post['title'] as String, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
        const SizedBox(height: 5),
        Text(post['body'] as String, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF788596), fontSize: 12, height: 1.4)),
        const SizedBox(height: 8),
        Row(children: [InkWell(onTap: onLike, child: Row(children: [Icon((post['liked'] ?? false) ? Icons.favorite_rounded : Icons.favorite_border_rounded, size: 17, color: AppPalette.pink), const SizedBox(width: 5), Text('${post['likes']}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800))])), const SizedBox(width: 16), const Icon(Icons.star_rounded, size: 15, color: Color(0xFFFFB547)), const SizedBox(width: 3), Text('${post['ratings']}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800)), const SizedBox(width: 12), const Icon(Icons.mode_comment_outlined, size: 15, color: Color(0xFF8994A4)), const SizedBox(width: 5), Text('${(post['comments'] as List).length} comments', style: const TextStyle(fontSize: 10, color: Color(0xFF8994A4)))]),
      ])),
    ])),
  );
}














class _ReaderAvatar extends StatelessWidget {
  const _ReaderAvatar({required this.author, this.imageUrl});
  final String author;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl?.trim() ?? '';
    final initial = author.replaceAll('@', '').trim();
    final fallback = CircleAvatar(
      radius: 16,
      backgroundColor: const Color(0xFFE8F1FF),
      child: Text(initial.isEmpty ? '?' : initial[0].toUpperCase(), style: const TextStyle(color: AppPalette.blue, fontWeight: FontWeight.w900, fontSize: 12)),
    );
    if (url.isEmpty) return fallback;
    return CircleAvatar(
      radius: 16,
      backgroundColor: const Color(0xFFE8F1FF),
      child: ClipOval(child: Image.network(url, width: 32, height: 32, fit: BoxFit.cover, errorBuilder: (_, __, ___) => fallback)),
    );
  }
}
