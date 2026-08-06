import 'package:flutter/material.dart';

const fireworkColors = [
  Colors.red,
  Colors.orange,
  Colors.yellow,
  Colors.pinkAccent,
  Colors.lightBlueAccent,
  Colors.purpleAccent,
  Colors.greenAccent,
];

Path drawFireworkSpark(Size size) {
  final path = Path();
  path.addOval(Rect.fromCircle(center: Offset(size.width / 2, size.height / 2), radius: size.width / 2));
  return path;
}
