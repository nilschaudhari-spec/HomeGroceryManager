import 'package:flutter/material.dart';
import 'services/ads_service.dart';
import 'services/app_language_service.dart';
import 'services/notification_service.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await AppLanguageService.instance.initialize();
  } catch (e, stack) {
    debugPrint('[Main] AppLanguageService initialization error: $e\n$stack');
  }
  try {
    await NotificationService.instance.initialize();
  } catch (e, stack) {
    debugPrint('[Main] NotificationService initialization error: $e\n$stack');
  }
  try {
    await AdsService.instance.initialize();
  } catch (e, stack) {
    debugPrint('[Main] AdsService initialization error: $e\n$stack');
  }
  runApp(const HomeGroceryApp());
}

class HomeGroceryApp extends StatelessWidget {
  const HomeGroceryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppLanguage>(
      valueListenable: AppLanguageService.instance.currentLanguageNotifier,
      builder: (context, currentLang, _) {
        return MaterialApp(
          title: AppLanguageService.t('app_title'),
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          locale: Locale(currentLang.code),
          home: const HomeScreen(),
        );
      },
    );
  }
}

