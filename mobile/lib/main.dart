import 'package:flutter/material.dart';

import 'widgets/mobile_footer.dart';
import 'widgets/mobile_header.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BaileSul',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3B82F6),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: MobileHeader.backgroundColor,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const Color contentBackgroundColor = Color(0xFFD7D7D7);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MobileHeader(
            onMenuPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Menu em breve')),
              );
            },
          ),
          Expanded(
            child: ColoredBox(
              color: contentBackgroundColor,
              child: Center(
                child: Text(
                  'Conteúdo',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: const Color(0xFF0A0C12),
                      ),
                ),
              ),
            ),
          ),
          const MobileFooter(),
        ],
      ),
    );
  }
}
