import 'package:flutter/material.dart';

class ManhwaCover extends StatelessWidget {
  const ManhwaCover({super.key, required this.variant, this.height = 190});
  final int variant;
  final double height;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: height,
        width: double.infinity,
        child: CustomPaint(painter: _CoverPainter(variant % 4)),
      );
}

class _CoverPainter extends CustomPainter {
  const _CoverPainter(this.variant);
  final int variant;

  @override
  void paint(Canvas canvas, Size size) {
    final palettes = [
      [const Color(0xFF1374D9), const Color(0xFF64C7E9), const Color(0xFFFFD585)],
      [const Color(0xFF382C67), const Color(0xFFCA6588), const Color(0xFFFFD19B)],
      [const Color(0xFFF29AA8), const Color(0xFFFFD7B0), const Color(0xFF759CCB)],
      [const Color(0xFF263B78), const Color(0xFF7053A8), const Color(0xFFFFD580)],
    ][variant];
    final rect = Offset.zero & size;
    final background = Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [palettes[0], palettes[1], palettes[2]]).createShader(rect);
    canvas.drawRect(rect, background);

    final glow = Paint()..color = const Color(0xFFFFF4CA).withValues(alpha: 0.72);
    canvas.drawCircle(Offset(size.width * .78, size.height * .22), size.height * .13, glow);
    final cloud = Paint()..color = Colors.white.withValues(alpha: .48);
    for (var i = 0; i < 5; i++) {
      final x = size.width * (.09 + i * .2);
      final y = size.height * (.46 + (i.isEven ? .04 : -.01));
      canvas.drawOval(Rect.fromCenter(center: Offset(x, y), width: size.width * .25, height: size.height * .09), cloud);
    }

    final farHill = Paint()..color = palettes[1].withValues(alpha: .8);
    final hillPath = Path()
      ..moveTo(0, size.height * .76)
      ..quadraticBezierTo(size.width * .23, size.height * .58, size.width * .42, size.height * .78)
      ..quadraticBezierTo(size.width * .69, size.height * .56, size.width, size.height * .72)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(hillPath, farHill);

    final personX = size.width * (variant == 2 ? .52 : .5);
    final headY = size.height * .38;
    final hair = Paint()..color = const Color(0xFF242033);
    final skin = Paint()..color = const Color(0xFFFFD4BD);
    final outfit = Paint()..color = variant == 2 ? const Color(0xFFF4F2F6) : const Color(0xFF252B43);
    final highlight = Paint()..color = const Color(0xFFFFF7E8).withValues(alpha: .9);

    // Flowing cape and shoulders.
    final cape = Path()
      ..moveTo(personX - size.width * .04, headY + size.height * .1)
      ..quadraticBezierTo(personX - size.width * .27, headY + size.height * .14, personX - size.width * .31, size.height)
      ..lineTo(personX + size.width * .3, size.height)
      ..quadraticBezierTo(personX + size.width * .23, headY + size.height * .1, personX + size.width * .04, headY + size.height * .08)
      ..close();
    canvas.drawPath(cape, outfit);

    // Neck, face and hair make an original, graphic cover illustration.
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(personX, headY + size.height * .13), width: size.width * .065, height: size.height * .12), const Radius.circular(8)), skin);
    canvas.drawOval(Rect.fromCenter(center: Offset(personX, headY), width: size.width * .17, height: size.height * .22), skin);
    final hairPath = Path()
      ..moveTo(personX - size.width * .09, headY + size.height * .02)
      ..quadraticBezierTo(personX - size.width * .14, headY - size.height * .17, personX, headY - size.height * .11)
      ..quadraticBezierTo(personX + size.width * .12, headY - size.height * .15, personX + size.width * .09, headY + size.height * .05)
      ..lineTo(personX + size.width * .035, headY - size.height * .01)
      ..lineTo(personX - size.width * .015, headY + size.height * .08)
      ..lineTo(personX - size.width * .04, headY + size.height * .015)
      ..lineTo(personX - size.width * .085, headY + size.height * .085)
      ..close();
    canvas.drawPath(hairPath, hair);
    canvas.drawLine(Offset(personX - size.width * .045, headY + size.height * .025), Offset(personX - size.width * .018, headY + size.height * .025), Paint()..color = const Color(0xFF332A35)..strokeWidth = 1.5);
    canvas.drawLine(Offset(personX + size.width * .018, headY + size.height * .025), Offset(personX + size.width * .045, headY + size.height * .025), Paint()..color = const Color(0xFF332A35)..strokeWidth = 1.5);
    final collar = Path()
      ..moveTo(personX - size.width * .055, headY + size.height * .09)
      ..lineTo(personX, headY + size.height * .3)
      ..lineTo(personX + size.width * .055, headY + size.height * .09)
      ..close();
    canvas.drawPath(collar, highlight);

    // Decorative sparkles add the illustrated webtoon cover feel.
    final sparkle = Paint()..color = const Color(0xFFFFF4C7).withValues(alpha: .95)..strokeWidth = 2;
    for (final point in [Offset(size.width * .18, size.height * .25), Offset(size.width * .84, size.height * .55), Offset(size.width * .25, size.height * .62)]) {
      canvas.drawLine(point.translate(-4, 0), point.translate(4, 0), sparkle);
      canvas.drawLine(point.translate(0, -4), point.translate(0, 4), sparkle);
    }
  }

  @override
  bool shouldRepaint(covariant _CoverPainter oldDelegate) => oldDelegate.variant != variant;
}

