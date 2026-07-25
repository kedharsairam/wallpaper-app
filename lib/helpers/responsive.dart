import 'package:flutter/material.dart';

/// Responsive image sizing helpers.
///
/// Every image in the app MUST use these helpers to decode at the
/// correct display size. Without this, 4K images consume ~32MB each
/// and cause OOM crashes on mid-range devices.
class Responsive {
  Responsive._();

  /// Returns the number of display pixels for a given logical size.
  ///
  /// Use this as [memCacheWidth] / [memCacheHeight] on every
  /// [CachedNetworkImage] and [ResizeImage] call.
  static int displayPixels(BuildContext context, double logicalPixels) {
    return (logicalPixels * MediaQuery.of(context).devicePixelRatio).round();
  }

  /// Grid tile decode size (matches maxCrossAxisExtent: 170).
  static int gridTileWidth(BuildContext context) {
    return displayPixels(context, 170);
  }

  /// Full-screen decode size (detail view).
  static int screenWidth(BuildContext context) {
    return displayPixels(context, MediaQuery.of(context).size.width);
  }

  /// Full-screen height decode size (detail view).
  static int screenHeight(BuildContext context) {
    return displayPixels(context, MediaQuery.of(context).size.height);
  }
}
