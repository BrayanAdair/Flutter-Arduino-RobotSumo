import 'package:flutter/material.dart';

import 'screens/connection_screen.dart';
import 'screens/control_screen.dart';

void main() {
  runApp(const RobotSumoApp());
}

class RobotSumoApp extends StatelessWidget {
  const RobotSumoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Robot Sumo Control',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.blueGrey,
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const ConnectionScreen(),
        '/control': (context) => const ControlScreen(),
      },
    );
  }
}
