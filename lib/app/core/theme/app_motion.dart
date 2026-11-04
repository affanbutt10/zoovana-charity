import 'package:flutter/animation.dart';

abstract final class AppMotion {
  static const fast = Duration(milliseconds: 180);
  static const medium = Duration(milliseconds: 320);
  static const slow = Duration(milliseconds: 520);
  static const pageTransition = Duration(milliseconds: 400);

  /// Gap between consecutive items of a cascading entrance.
  static const stagger = Duration(milliseconds: 55);

  static const curve = Curves.easeOutCubic;

  /// For movement that both starts and ends on screen, like paging.
  static const emphasized = Curves.easeInOutCubic;

  /// Slight overshoot for elements that pop into place.
  static const spring = Curves.easeOutBack;
}
