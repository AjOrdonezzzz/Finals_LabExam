import 'package:flutter/material.dart';

import 'manhwa_cover.dart';

class RecommendationCover extends StatelessWidget {
  const RecommendationCover({super.key, required this.variant, required this.height, this.imageUrl});
  final int variant;
  final double height;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl?.trim() ?? '';
    if (url.isEmpty) return ManhwaCover(variant: variant, height: height);
    return SizedBox(
      height: height,
      width: double.infinity,
      child: Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => ManhwaCover(variant: variant, height: height),
        loadingBuilder: (context, child, progress) => progress == null
            ? child
            : Stack(fit: StackFit.expand, children: [
                ManhwaCover(variant: variant, height: height),
                const Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))),
              ]),
      ),
    );
  }
}

