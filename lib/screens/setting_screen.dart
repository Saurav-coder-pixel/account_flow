import 'package:flutter/material.dart';

import '../widgets/app_drawer.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {

  final List<Color> gradientColors =
  [Colors.green.shade700, Colors.green.shade400];


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: AppDrawer(gradientColors: gradientColors),
    );
  }
}
