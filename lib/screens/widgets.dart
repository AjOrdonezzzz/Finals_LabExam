import 'package:flutter/material.dart';

const Color kPrimary = Color(0xFF2C4463);
const Color kTint = Color(0xFFE8EDF4);
const Color kGrey = Color(0xFF8A8A8A);
const Color kBorder = Color(0xFFE6E6E6);

const genres = [
  'Action',
  'Fantasy',
  'Romance',
  'Drama',
  'Comedy',
  'Supernatural',
  'Thriller',
  'Slice of Life',
];

/// Avatar generated from a username (png, because Image.network can't show svg)
String avatarFor(String name) =>
    'https://api.dicebear.com/7.x/avataaars/png?seed=${Uri.encodeComponent(name)}';

/// Converts a post (from API or arguments) into the Map stored in Hive
Map<String, dynamic> postToFavorite(Map p) => {
      'id': p['id'].toString(),
      'title': p['title'] ?? '',
      'body': p['body'] ?? '',
      'image': p['image'] ?? '',
      'ratings': p['ratings'],
      'genre': p['genre'] ?? '',
      'recommendedBy': p['recommendedBy'] ?? 'anonymous',
      'avatar': p['avatar'] ?? '',
      'note': '',
    };

class CoverImage extends StatelessWidget {
  final String? url;
  final double width;
  final double height;

  const CoverImage({
    super.key,
    required this.url,
    this.width = 80,
    this.height = 110,
  });

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: kTint,
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Icon(Icons.menu_book_rounded, color: kPrimary),
    );

    if (url == null || !url!.startsWith('http')) return placeholder;

    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Image.network(
        url!,
        width: width,
        height: height,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) => progress == null
            ? child
            : SizedBox(
                width: width,
                height: height,
                child: const Center(
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: kPrimary),
                ),
              ),
        errorBuilder: (context, error, stack) => placeholder,
      ),
    );
  }
}

class UserAvatar extends StatelessWidget {
  final String? url;
  final String name;
  final double radius;

  const UserAvatar({
    super.key,
    required this.url,
    required this.name,
    this.radius = 20,
  });

  @override
  Widget build(BuildContext context) {
    final hasUrl = url != null && url!.startsWith('http');
    return CircleAvatar(
      radius: radius,
      backgroundColor: kTint,
      foregroundImage: hasUrl ? NetworkImage(url!) : null,
      onForegroundImageError: hasUrl ? (_, __) {} : null,
      child: Text(
        name.isEmpty ? '?' : name[0].toUpperCase(),
        style: const TextStyle(color: kPrimary, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class GenreChip extends StatelessWidget {
  final String genre;
  const GenreChip({super.key, required this.genre});

  @override
  Widget build(BuildContext context) {
    if (genre.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: kTint,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        genre,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: kPrimary,
        ),
      ),
    );
  }
}

class RatingBadge extends StatelessWidget {
  final num? rating;
  const RatingBadge({super.key, required this.rating});

  @override
  Widget build(BuildContext context) {
    if (rating == null || rating == 0) {
      return const Text('Not rated',
          style: TextStyle(fontSize: 13, color: kGrey));
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.star_rounded, color: Color(0xFFFFB400), size: 18),
        const SizedBox(width: 3),
        Text(
          rating!.toDouble().toStringAsFixed(1),
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
        ),
      ],
    );
  }
}
