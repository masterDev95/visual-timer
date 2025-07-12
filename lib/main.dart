import 'package:flutter/material.dart';
import 'package:timer/screens/timer_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Minuteur Visuel',
      darkTheme: ThemeData.dark(),
      theme: ThemeData.light(),
      themeMode: ThemeMode.system,
      home: const TimerScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
