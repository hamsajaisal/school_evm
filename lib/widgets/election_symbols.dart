import 'dart:math' as math;
import 'package:flutter/material.dart';

class ElectionSymbol extends StatelessWidget {
  final String name;
  final double size;
  final Color? color;

  const ElectionSymbol({
    super.key,
    required this.name,
    this.size = 64.0,
    this.color,
  });

  static const List<String> availableSymbols = [
    'Apple',
    'Mango',
    'Watermelon',
    'Carrot',
    'Tomato',
    'Pencil',
    'Book',
    'Cricket Bat',
    'Football',
    'Trophy',
    'Umbrella',
    'Clock',
    'Key',
    'Balloon',
    'Pumpkin'
  ];

  @override
  Widget build(BuildContext context) {
    final defaultColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : Colors.black87;

    return Semantics(
      label: 'Symbol: $name',
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(size * 0.15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            )
          ],
        ),
        padding: EdgeInsets.all(size * 0.12),
        child: CustomPaint(
          size: Size(size, size),
          painter: _SymbolPainter(name, color ?? defaultColor),
        ),
      ),
    );
  }
}

class _SymbolPainter extends CustomPainter {
  final String symbolName;
  final Color tintColor;

  _SymbolPainter(this.symbolName, this.tintColor);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = tintColor
      ..style = PaintingStyle.fill
      ..strokeWidth = 2.0;

    final strokePaint = Paint()
      ..color = tintColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.04
      ..strokeCap = StrokeCap.round;

    final w = size.width;
    final h = size.height;

    switch (symbolName) {
      case 'Apple':
        // Draw apple body
        final path = Path()
          ..moveTo(w * 0.5, h * 0.35)
          ..cubicTo(w * 0.3, h * 0.2, w * 0.1, h * 0.4, w * 0.15, h * 0.7)
          ..cubicTo(w * 0.2, h * 0.95, w * 0.45, h * 0.95, w * 0.5, h * 0.85)
          ..cubicTo(w * 0.55, h * 0.95, w * 0.8, h * 0.95, w * 0.85, h * 0.7)
          ..cubicTo(w * 0.9, h * 0.4, w * 0.7, h * 0.2, w * 0.5, h * 0.35)
          ..close();
        canvas.drawPath(path, paint);

        // Draw Stem
        final stemPath = Path()
          ..moveTo(w * 0.5, h * 0.3)
          ..quadraticBezierTo(w * 0.55, h * 0.1, w * 0.7, h * 0.08);
        canvas.drawPath(stemPath, strokePaint);

        // Draw Leaf
        final leafPath = Path()
          ..moveTo(w * 0.55, h * 0.22)
          ..quadraticBezierTo(w * 0.7, h * 0.15, w * 0.75, h * 0.25)
          ..quadraticBezierTo(w * 0.65, h * 0.32, w * 0.55, h * 0.22)
          ..close();
        canvas.drawPath(leafPath, Paint()..color = tintColor.withOpacity(0.8));
        break;

      case 'Mango':
        final path = Path()
          ..moveTo(w * 0.45, h * 0.2)
          ..cubicTo(w * 0.15, h * 0.25, w * 0.05, h * 0.65, w * 0.25, h * 0.85)
          ..cubicTo(w * 0.45, h * 1.0, w * 0.75, h * 0.95, w * 0.85, h * 0.7)
          ..cubicTo(w * 0.95, h * 0.45, w * 0.8, h * 0.25, w * 0.65, h * 0.18)
          ..cubicTo(w * 0.55, h * 0.15, w * 0.5, h * 0.15, w * 0.45, h * 0.2)
          ..close();
        canvas.drawPath(path, paint);

        // Stem
        final stem = Path()
          ..moveTo(w * 0.52, h * 0.18)
          ..quadraticBezierTo(w * 0.52, h * 0.08, w * 0.58, h * 0.05);
        canvas.drawPath(stem, strokePaint);
        break;

      case 'Watermelon':
        // Rind / Outer Slice
        final sliceRect = Rect.fromLTWH(0, 0, w, h);
        canvas.drawArc(sliceRect, 0, math.pi, false, strokePaint);
        
        // inner flesh
        final fleshPaint = Paint()
          ..color = tintColor.withOpacity(0.7)
          ..style = PaintingStyle.fill;
        canvas.drawArc(
          Rect.fromLTWH(w * 0.1, h * 0.1, w * 0.8, h * 0.8),
          0,
          math.pi,
          true,
          fleshPaint,
        );

        // Seeds
        final seedPaint = Paint()..color = tintColor;
        canvas.drawCircle(Offset(w * 0.35, h * 0.6), w * 0.03, seedPaint);
        canvas.drawCircle(Offset(w * 0.5, h * 0.7), w * 0.03, seedPaint);
        canvas.drawCircle(Offset(w * 0.65, h * 0.6), w * 0.03, seedPaint);
        break;

      case 'Carrot':
        // Root cone
        final path = Path()
          ..moveTo(w * 0.35, h * 0.2)
          ..lineTo(w * 0.65, h * 0.2)
          ..quadraticBezierTo(w * 0.65, h * 0.4, w * 0.55, h * 0.75)
          ..lineTo(w * 0.5, h * 0.95)
          ..lineTo(w * 0.45, h * 0.75)
          ..quadraticBezierTo(w * 0.35, h * 0.4, w * 0.35, h * 0.2)
          ..close();
        canvas.drawPath(path, paint);

        // Leafy tops
        canvas.drawLine(Offset(w * 0.45, h * 0.2), Offset(w * 0.35, h * 0.05), strokePaint);
        canvas.drawLine(Offset(w * 0.5, h * 0.2), Offset(w * 0.5, h * 0.03), strokePaint);
        canvas.drawLine(Offset(w * 0.55, h * 0.2), Offset(w * 0.65, h * 0.05), strokePaint);
        break;

      case 'Tomato':
        // Main sphere
        canvas.drawCircle(Offset(w * 0.5, h * 0.55), w * 0.4, paint);
        
        // Leaf crown
        final crown = Path()
          ..moveTo(w * 0.5, h * 0.2)
          ..lineTo(w * 0.35, h * 0.1)
          ..lineTo(w * 0.42, h * 0.22)
          ..lineTo(w * 0.5, h * 0.08) // stem top
          ..lineTo(w * 0.58, h * 0.22)
          ..lineTo(w * 0.65, h * 0.1)
          ..lineTo(w * 0.5, h * 0.2)
          ..close();
        canvas.drawPath(crown, Paint()..color = tintColor);
        break;

      case 'Pencil':
        // Tip
        final path = Path()
          ..moveTo(w * 0.2, h * 0.8)
          ..lineTo(w * 0.8, h * 0.2)
          ..lineTo(w * 0.68, h * 0.08)
          ..lineTo(w * 0.08, h * 0.68)
          ..close();
        canvas.drawPath(path, paint);

        // Pencil tip cone & lead
        final tip = Path()
          ..moveTo(w * 0.8, h * 0.2)
          ..lineTo(w * 0.95, h * 0.05)
          ..lineTo(w * 0.68, h * 0.08)
          ..close();
        canvas.drawPath(tip, Paint()..color = tintColor.withOpacity(0.6));
        canvas.drawCircle(Offset(w * 0.9, h * 0.1), w * 0.05, Paint()..color = tintColor);
        break;

      case 'Book':
        // Pages
        final path = Path()
          ..moveTo(w * 0.5, h * 0.85)
          ..quadraticBezierTo(w * 0.25, h * 0.75, w * 0.05, h * 0.8)
          ..lineTo(w * 0.05, h * 0.25)
          ..quadraticBezierTo(w * 0.25, h * 0.2, w * 0.5, h * 0.3)
          ..quadraticBezierTo(w * 0.75, h * 0.2, w * 0.95, h * 0.25)
          ..lineTo(w * 0.95, h * 0.8)
          ..quadraticBezierTo(w * 0.75, h * 0.75, w * 0.5, h * 0.85)
          ..close();
        canvas.drawPath(path, paint);

        // Center spine line
        canvas.drawLine(Offset(w * 0.5, h * 0.3), Offset(w * 0.5, h * 0.85), strokePaint);
        break;

      case 'Cricket Bat':
        final handlePaint = Paint()
          ..color = tintColor.withOpacity(0.7)
          ..style = PaintingStyle.stroke
          ..strokeWidth = w * 0.06;

        // Grip handle
        canvas.drawLine(Offset(w * 0.2, h * 0.2), Offset(w * 0.45, h * 0.45), handlePaint);
        
        // Wooden blade
        final batBody = Path()
          ..moveTo(w * 0.4, h * 0.4)
          ..lineTo(w * 0.85, h * 0.85)
          ..lineTo(w * 0.75, h * 0.95)
          ..lineTo(w * 0.3, h * 0.5)
          ..close();
        canvas.drawPath(batBody, paint);
        break;

      case 'Football':
        // Main sphere
        canvas.drawCircle(Offset(w * 0.5, h * 0.5), w * 0.45, strokePaint);
        
        // Star pattern segments inside
        canvas.drawCircle(Offset(w * 0.5, h * 0.5), w * 0.12, paint);
        
        // Rays to mock pentagons
        for (var i = 0; i < 5; i++) {
          final angle = (i * 2 * math.pi / 5) - math.pi / 2;
          final innerPoint = Offset(
            w * 0.5 + w * 0.12 * math.cos(angle),
            h * 0.5 + h * 0.12 * math.sin(angle),
          );
          final outerPoint = Offset(
            w * 0.5 + w * 0.45 * math.cos(angle),
            h * 0.5 + h * 0.45 * math.sin(angle),
          );
          canvas.drawLine(innerPoint, outerPoint, strokePaint);
        }
        break;

      case 'Trophy':
        // Cup shape
        final cup = Path()
          ..moveTo(w * 0.2, h * 0.2)
          ..lineTo(w * 0.8, h * 0.2)
          ..quadraticBezierTo(w * 0.8, h * 0.6, w * 0.5, h * 0.65)
          ..quadraticBezierTo(w * 0.2, h * 0.6, w * 0.2, h * 0.2)
          ..close();
        canvas.drawPath(cup, paint);

        // Stand stem
        canvas.drawRect(Rect.fromLTWH(w * 0.43, h * 0.65, w * 0.14, h * 0.18), paint);
        
        // Base plate
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(w * 0.25, h * 0.83, w * 0.5, h * 0.1),
            Radius.circular(w * 0.02),
          ),
          paint,
        );

        // Handles
        final leftHandle = Path()
          ..moveTo(w * 0.2, h * 0.3)
          ..cubicTo(w * 0.05, h * 0.25, w * 0.05, h * 0.5, w * 0.2, h * 0.45);
        canvas.drawPath(leftHandle, strokePaint);

        final rightHandle = Path()
          ..moveTo(w * 0.8, h * 0.3)
          ..cubicTo(w * 0.95, h * 0.25, w * 0.95, h * 0.5, w * 0.8, h * 0.45);
        canvas.drawPath(rightHandle, strokePaint);
        break;

      case 'Umbrella':
        // Canopy dome
        canvas.drawArc(Rect.fromLTWH(0, h * 0.15, w, h * 0.7), math.pi, math.pi, true, paint);
        
        // Bottom curved indents of the canopy
        final indentPaint = Paint()..color = ThemeData().cardColor; // cut out
        for (var i = 0; i < 4; i++) {
          canvas.drawCircle(
            Offset(w * 0.125 + i * w * 0.25, h * 0.5),
            w * 0.125,
            indentPaint,
          );
        }

        // Shaft & Handle hook
        canvas.drawLine(Offset(w * 0.5, h * 0.5), Offset(w * 0.5, h * 0.85), strokePaint);
        
        final handleHook = Path()
          ..moveTo(w * 0.5, h * 0.85)
          ..quadraticBezierTo(w * 0.45, h * 0.95, w * 0.35, h * 0.92);
        canvas.drawPath(handleHook, strokePaint);
        break;

      case 'Clock':
        // Face ring
        canvas.drawCircle(Offset(w * 0.5, h * 0.5), w * 0.45, strokePaint);
        
        // Center pin
        canvas.drawCircle(Offset(w * 0.5, h * 0.5), w * 0.05, paint);
        
        // Hands
        canvas.drawLine(Offset(w * 0.5, h * 0.5), Offset(w * 0.5, h * 0.22), strokePaint); // Hour hand
        canvas.drawLine(Offset(w * 0.5, h * 0.5), Offset(w * 0.72, h * 0.5), strokePaint); // Minute hand
        break;

      case 'Key':
        // Circular head
        canvas.drawCircle(Offset(w * 0.3, h * 0.5), w * 0.2, strokePaint);
        canvas.drawCircle(Offset(w * 0.3, h * 0.5), w * 0.06, paint); // Hole
        
        // Shaft
        canvas.drawLine(Offset(w * 0.5, h * 0.5), Offset(w * 0.9, h * 0.5), strokePaint);
        
        // Teeth
        canvas.drawLine(Offset(w * 0.75, h * 0.5), Offset(w * 0.75, h * 0.65), strokePaint);
        canvas.drawLine(Offset(w * 0.85, h * 0.5), Offset(w * 0.85, h * 0.65), strokePaint);
        break;

      case 'Balloon':
        // Balloon body
        final path = Path()
          ..moveTo(w * 0.5, h * 0.1)
          ..cubicTo(w * 0.15, h * 0.1, w * 0.15, h * 0.6, w * 0.5, h * 0.75)
          ..cubicTo(w * 0.85, h * 0.6, w * 0.85, h * 0.1, w * 0.5, h * 0.1)
          ..close();
        canvas.drawPath(path, paint);

        // Little knot at bottom
        final knot = Path()
          ..moveTo(w * 0.45, h * 0.75)
          ..lineTo(w * 0.55, h * 0.75)
          ..lineTo(w * 0.5, h * 0.82)
          ..close();
        canvas.drawPath(knot, paint);

        // String
        final stringPath = Path()
          ..moveTo(w * 0.5, h * 0.82)
          ..quadraticBezierTo(w * 0.45, h * 0.9, w * 0.55, h * 0.98);
        canvas.drawPath(stringPath, strokePaint);
        break;

      case 'Pumpkin':
        // Outer lobes
        canvas.drawOval(Rect.fromLTWH(w * 0.1, h * 0.25, w * 0.8, h * 0.6), paint);
        canvas.drawOval(
          Rect.fromLTWH(w * 0.22, h * 0.25, w * 0.56, h * 0.6),
          Paint()..color = tintColor.withOpacity(0.9),
        );
        canvas.drawOval(
          Rect.fromLTWH(w * 0.35, h * 0.25, w * 0.3, h * 0.6),
          Paint()..color = tintColor.withOpacity(0.8),
        );

        // Stem
        final stem = Path()
          ..moveTo(w * 0.5, h * 0.25)
          ..quadraticBezierTo(w * 0.52, h * 0.1, w * 0.62, h * 0.08);
        canvas.drawPath(stem, strokePaint);
        break;

      default:
        // Generic box representation if symbol missing
        canvas.drawRect(Rect.fromLTWH(0, 0, w, h), strokePaint);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
