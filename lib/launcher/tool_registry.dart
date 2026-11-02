import 'package:flutter/material.dart';
import '../features/account_flow/account_flow_entry.dart';
import '../features/converters/converters_screen.dart';
import '../features/video_player/video_library_screen.dart';

/// Describes a single tool in the Toolbox launcher.
class ToolDefinition {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradientColors;
  final WidgetBuilder builder;
  final bool enabled;

  const ToolDefinition({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradientColors,
    required this.builder,
    this.enabled = true,
  });
}

/// The canonical list of tools. Adding a new tool = adding one entry here.
final List<ToolDefinition> toolRegistry = [
  ToolDefinition(
    id: 'account_flow',
    title: 'Account Flow',
    subtitle: 'Ledger, cashbook & splits',
    icon: Icons.account_balance_wallet_rounded,
    gradientColors: [const Color(0xFF1B5E20), const Color(0xFF43A047)],
    builder: (_) => const AccountFlowEntry(),
  ),
  ToolDefinition(
    id: 'converters',
    title: 'Converters',
    subtitle: 'PDF, image, and format tools',
    icon: Icons.transform_rounded,
    gradientColors: [const Color(0xFF0D47A1), const Color(0xFF1976D2)],
    builder: (_) => const ConvertersScreen(),
  ),
  ToolDefinition(
    id: 'video_player',
    title: 'Video Player',
    subtitle: 'Speed-controlled local player',
    icon: Icons.play_circle_filled_rounded,
    gradientColors: [const Color(0xFF4A148C), const Color(0xFF7B1FA2)],
    builder: (_) => const VideoLibraryScreen(),
  ),
  ToolDefinition(
    id: 'coming_soon',
    title: 'Coming Soon',
    subtitle: 'More tools on the way!',
    icon: Icons.add_circle_rounded,
    gradientColors: [const Color(0xFF37474F), const Color(0xFF607D8B)],
    builder: (_) => const _ComingSoonScreen(),
    enabled: false,
  ),
];

class _ComingSoonScreen extends StatelessWidget {
  const _ComingSoonScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Coming Soon')),
      body: const Center(
        child: Text('This tool is coming soon!', style: TextStyle(fontSize: 20)),
      ),
    );
  }
}
