import 'package:flutter/material.dart';

abstract final class AppRadius {
  static const double small = 8;
  static const double medium = 12;
  static const double large = 16;
  static const double xLarge = 20;
  static const double xxLarge = 24;
  static const double field = 28;
  static const double pill = 100;

  static final BorderRadius largeAll = BorderRadius.circular(large);
  static final BorderRadius xLargeAll = BorderRadius.circular(xLarge);
}
