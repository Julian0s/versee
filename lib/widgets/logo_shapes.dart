import 'package:flutter/material.dart';

class VShapeLogoShape extends CustomPainter {
  final Gradient gradient;

  VShapeLogoShape({required this.gradient});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = gradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final path = Path();
    
    // Create V shape - trapezoid that narrows at bottom
    // Top left point
    path.moveTo(0, 0);
    // Top right point  
    path.lineTo(size.width, 0);
    // Bottom right point (narrower)
    path.lineTo(size.width * 0.75, size.height);
    // Bottom left point (narrower)
    path.lineTo(size.width * 0.25, size.height);
    // Close the shape
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class JShapeLogoShape extends CustomPainter {
  final Gradient gradient;

  JShapeLogoShape({required this.gradient});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = gradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final path = Path();
    
    // Create J shape - rounded rectangle with curve at bottom
    // Top section (horizontal bar)
    path.moveTo(0, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height * 0.2);
    
    // Right vertical section
    path.lineTo(size.width * 0.7, size.height * 0.2);
    path.lineTo(size.width * 0.7, size.height * 0.7);
    
    // Bottom curved section
    path.quadraticBezierTo(
      size.width * 0.7, size.height,  // Control point
      size.width * 0.3, size.height,  // End point
    );
    
    path.quadraticBezierTo(
      0, size.height,  // Control point
      0, size.height * 0.7,  // End point
    );
    
    // Left vertical section back to top
    path.lineTo(0, size.height * 0.2);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}