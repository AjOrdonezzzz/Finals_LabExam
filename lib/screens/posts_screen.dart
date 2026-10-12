import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;

import 'widgets.dart';

const String apiUrl = 'https://6acca40ab406cb8ec0c6239b.mockapi.io/post';

class PostsScreen extends StatefulWidget {
  const PostsScreen({super.key});

  @override
  State<PostsScreen> createState() => _PostsScreenState();
}

class _PostsScreenState extends State<PostsScreen> {
  List<Map<String, dynamic>> posts = [];
  bool isLoading = true;
  String? errorMessage;
  String selectedGenre = 'All';

  @override
  void initState() {
    super.initState();
    fetchPosts();
  }

  // ---------- GET ----------
  Future<void> fetchPosts() async {
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        setState(() {
          posts = data
              .map((e) => Map<String, dynamic>.from(e))
              .toList()
              .reversed
              .toList(); // newest first
          errorMessage = null;
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Failed to load posts (code ${response.statusCode})';
          isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        errorMessage = 'Something went wrong: $e';
        isLoading = false;
      });
    }
  }

  // ---------- POST ----------
  Future<void> openAddSheet() async {
    final data = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const AddPostSheet(),
    );
    if (data != null) await createPost(data);
  }

  Future<void> createPost(Map<String, dynamic> data) async {
    String message;
    bool ok = false;
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode(data),
      );
      ok = response.statusCode == 201;
      message = ok
          ? 'Recommendation posted!'
          : 'Failed to post (code ${response.statusCode})';
    } catch (e) {
      message = 'Failed to post: $e';
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
    if (ok) fetchPosts();
  }

  // ---------- HEADER: welcome + status card ----------
  String get topGenre {
    final counts = <String, int>{};
    for (final p in posts) {
      final g = (p['genre'] ?? '').toString();
      if (g.isNotEmpty) counts[g] = (counts[g] ?? 0) + 1;
    }
    if (counts.isEmpty) return '-';
    return counts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }

  Widget statItem(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget statDivider() =>
      Container(width: 1, height: 32, color: Colors.white24);

  Widget buildHeader(Box box) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Welcome back, reader',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          const Text(
            'Discover manhwa recommended by the community.',
            style: TextStyle(color: kGrey, fontSize: 14),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            decoration: BoxDecoration(
              color: kPrimary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                statItem('${posts.length}', 'Recommendations'),
                statDivider(),
                statItem('${box.length}', 'Saved'),
                statDivider(),
                statItem(topGenre, 'Top genre'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------- UI ----------
  Widget buildGenreTabs() {
    final options = ['All', ...genres];
    return SizedBox(
      height: 46,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: options.length,
        itemBuilder: (context, i) {
          final g = options[i];
          final selected = g == selectedGenre;
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() => selectedGenre = g),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    g,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                      color: selected ? kPrimary : kGrey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 3,
                    width: 24,
                    color: selected ? kPrimary : Colors.transparent,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget buildPost(Map<String, dynamic> post, Box box) {
    final id = post['id'].toString();
    final saved = box.containsKey(id);
    final user = (post['recommendedBy'] ?? 'anonymous').toString();

    void openDetails() {
      Navigator.pushNamed(
        context,
        '/details',
        arguments: {
          'id': id,
          'title': post['title'],
          'body': post['body'],
          'image': post['image'],
          'ratings': post['ratings'],
          'genre': post['genre'],
          'recommendedBy': user,
          'avatar': post['avatar'],
        },
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row: avatar + manhwa title + recommender
        ListTile(
          contentPadding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
          onTap: openDetails,
          leading: UserAvatar(url: post['avatar']?.toString(), name: user),
          title: Text(
            post['title']?.toString() ?? 'Untitled',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          subtitle: Text(
            '@$user recommends this',
            style: const TextStyle(color: kGrey, fontSize: 13),
          ),
          trailing: const Icon(Icons.more_horiz, color: kGrey),
        ),

        // Content, indented to line up under the title (16 + 40 + 16 = 72)
        Padding(
          padding: const EdgeInsets.fromLTRB(72, 6, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                post['body']?.toString() ?? '',
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14.5, height: 1.4),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: openDetails,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F9FB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: kBorder),
                  ),
                  child: Row(
                    children: [
                      CoverImage(url: post['image']?.toString()),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GenreChip(genre: post['genre']?.toString() ?? ''),
                            const SizedBox(height: 10),
                            RatingBadge(rating: post['ratings'] as num?),
                            const SizedBox(height: 10),
                            const Text(
                              'Tap to read more',
                              style: TextStyle(color: kGrey, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Action row, with the heart icon aligned to the content edge
        Padding(
          padding: const EdgeInsets.only(left: 64, top: 4, bottom: 4),
          child: Row(
            children: [
              IconButton(
                tooltip: saved ? 'Remove from favorites' : 'Save',
                icon: Icon(
                  saved ? Icons.favorite : Icons.favorite_border,
                  color: saved ? Colors.red : Colors.black54,
                ),
                onPressed: () {
                  if (saved) {
                    box.delete(id);
                  } else {
                    box.put(id, postToFavorite(post));
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.chat_bubble_outline,
                    color: Colors.black54),
                onPressed: openDetails,
              ),
            ],
          ),
        ),
        const Divider(),
      ],
    );
  }

  Widget buildBody() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator(color: kPrimary));
    }
    if (errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                errorMessage!,
                style: const TextStyle(color: Colors.red, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    isLoading = true;
                    errorMessage = null;
                  });
                  fetchPosts();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final shown = selectedGenre == 'All'
        ? posts
        : posts.where((p) => p['genre'] == selectedGenre).toList();
    final box = Hive.box('favoritesBox');

    return Column(
      children: [
        buildGenreTabs(),
        const Divider(),
        Expanded(
          child: RefreshIndicator(
            color: kPrimary,
            onRefresh: fetchPosts,
            child: ValueListenableBuilder(
              valueListenable: box.listenable(),
              builder: (context, Box b, _) {
                final count = shown.isEmpty ? 2 : shown.length + 1;
                return ListView.builder(
                  itemCount: count,
                  itemBuilder: (context, index) {
                    if (index == 0) return buildHeader(b);
                    if (shown.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(40),
                        child:
                            Center(child: Text('No recommendations here yet')),
                      );
                    }
                    return buildPost(shown[index - 1], b);
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'MANHWA THREADS',
          style: TextStyle(
            color: kPrimary,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite_border),
            tooltip: 'Favorites',
            onPressed: () => Navigator.pushNamed(context, '/favorites'),
          ),
        ],
      ),
      body: buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: openAddSheet,
        child: const Icon(Icons.edit_rounded),
      ),
    );
  }
}

// ====================== BOTTOM SHEET (add post) ======================
class AddPostSheet extends StatefulWidget {
  const AddPostSheet({super.key});

  @override
  State<AddPostSheet> createState() => _AddPostSheetState();
}

class _AddPostSheetState extends State<AddPostSheet> {
  final titleC = TextEditingController();
  final bodyC = TextEditingController();
  final imageC = TextEditingController();
  final userC = TextEditingController();
  final formKey = GlobalKey<FormState>();
  String genre = genres.first;
  double rating = 8;

  @override
  void dispose() {
    titleC.dispose();
    bodyC.dispose();
    imageC.dispose();
    userC.dispose();
    super.dispose();
  }

  void submit() {
    if (!formKey.currentState!.validate()) return;
    final user = userC.text.trim().isEmpty ? 'anonymous' : userC.text.trim();
    Navigator.pop(context, {
      'title': titleC.text.trim(),
      'body': bodyC.text.trim(),
      'image': imageC.text.trim(),
      'ratings': double.parse(rating.toStringAsFixed(1)),
      'genre': genre,
      'recommendedBy': user,
      'avatar': avatarFor(user),
    });
  }

  InputDecoration deco(String label) => InputDecoration(
        labelText: label,
        filled: true,
        fillColor: const Color(0xFFF5F7FA),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Recommend a manhwa',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              TextFormField(
                controller: titleC,
                decoration: deco('Manhwa title'),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Title is required'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: bodyC,
                decoration: deco('Why do you recommend it?'),
                maxLines: 3,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Body is required' : null,
              ),
              const SizedBox(height: 16),
              const Text('Genre',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: genres.map((g) {
                  final selected = g == genre;
                  return ChoiceChip(
                    label: Text(g),
                    selected: selected,
                    showCheckmark: false,
                    selectedColor: kPrimary,
                    backgroundColor: const Color(0xFFF5F7FA),
                    side: BorderSide.none,
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : Colors.black,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                    ),
                    onSelected: (_) => setState(() => genre = g),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              Text('Your rating: ${rating.toStringAsFixed(1)} / 10',
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              Slider(
                value: rating,
                min: 0,
                max: 10,
                divisions: 100,
                activeColor: kPrimary,
                onChanged: (v) => setState(() => rating = v),
              ),
              TextFormField(
                controller: imageC,
                decoration: deco('Cover image URL (optional)'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: userC,
                decoration: deco('Your username (optional)'),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: submit,
                  child: const Text('Post', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
