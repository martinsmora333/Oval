import 'package:flutter/material.dart';

import '../map/map_screen.dart' as canonical;

/// Deprecated compatibility wrapper for the canonical map screen.
class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const canonical.MapScreen();
  }
}
