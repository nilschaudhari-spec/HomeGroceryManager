import 'package:flutter/material.dart';
import 'services/ads_service.dart';
import 'services/notification_service.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.instance.initialize();
  await AdsService.instance.initialize();
  runApp(const HomeGroceryApp());
}

class HomeGroceryApp extends StatelessWidget {
  const HomeGroceryApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Home Grocery Manager',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF26734D)), useMaterial3: true, scaffoldBackgroundColor: const Color(0xFFF7F8F5), appBarTheme: const AppBarTheme(centerTitle: false)),
    home: const HomeScreen(),
  );
}
