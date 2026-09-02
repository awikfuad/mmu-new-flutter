import 'package:flutter/material.dart';

class CurvedUpClipper extends CustomClipper<Path> {
  final double curveDepth;

  CurvedUpClipper({required this.curveDepth});

  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height);

    final controlPoint = Offset(size.width / 2, size.height - (curveDepth * 2));
    final endPoint = Offset(size.width, size.height);

    path.quadraticBezierTo(
      controlPoint.dx,
      controlPoint.dy,
      endPoint.dx,
      endPoint.dy,
    );

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CurvedUpClipper oldClipper) {
    return oldClipper.curveDepth != curveDepth;
  }
}