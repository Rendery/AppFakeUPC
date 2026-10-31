import 'package:flutter/painting.dart';

// Oswald va empaquetada como fuente variable (assets/fonts/Oswald.ttf); el peso se
// fija también como eje 'wght' para que no dependa de la coincidencia por peso.
TextStyle oswald({
  required double fontSize,
  required FontWeight fontWeight,
  Color? color,
  double? letterSpacing,
}) {
  return TextStyle(
    fontFamily: 'Oswald',
    fontSize: fontSize,
    fontWeight: fontWeight,
    fontVariations: [FontVariation('wght', fontWeight.value.toDouble())],
    color: color,
    letterSpacing: letterSpacing,
  );
}
