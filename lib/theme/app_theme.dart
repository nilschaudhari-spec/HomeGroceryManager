import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF0D5335);
  static const primaryGradientStart = Color(0xFF0D5335);
  static const primaryGradientEnd = Color(0xFF16794E);
  static const accentMint = Color(0xFF10B981);
  static const mintLight = Color(0xFFE8F5E9);
  static const mintDark = Color(0xFF065F46);

  static const background = Color(0xFFF8FAFC);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceElevated = Color(0xFFF1F5F9);
  static const cardBorder = Color(0xFFE2E8F0);

  static const textPrimary = Color(0xFF0F172A);
  static const textSecondary = Color(0xFF475569);
  static const textMuted = Color(0xFF94A3B8);

  static const warning = Color(0xFFF59E0B);
  static const warningBg = Color(0xFFFEF3C7);
  static const warningBorder = Color(0xFFFCD34D);

  static const danger = Color(0xFFEF4444);
  static const dangerBg = Color(0xFFFEE2E2);

  static const info = Color(0xFF0284C7);
  static const infoBg = Color(0xFFE0F2FE);
}

class CategoryMeta {
  final String name;
  final String emoji;
  final IconData icon;
  final Color color;
  final Color bgColor;

  const CategoryMeta({
    required this.name,
    required this.emoji,
    required this.icon,
    required this.color,
    required this.bgColor,
  });

  static const Map<String, CategoryMeta> all = {
    'Staples': CategoryMeta(
      name: 'Staples',
      emoji: '🌾',
      icon: Icons.grain_rounded,
      color: Color(0xFFB45309),
      bgColor: Color(0xFFFEF3C7),
    ),
    'Dairy': CategoryMeta(
      name: 'Dairy',
      emoji: '🥛',
      icon: Icons.local_drink_rounded,
      color: Color(0xFF0284C7),
      bgColor: Color(0xFFE0F2FE),
    ),
    'Vegetables': CategoryMeta(
      name: 'Vegetables',
      emoji: '🥦',
      icon: Icons.eco_rounded,
      color: Color(0xFF15803D),
      bgColor: Color(0xFFDCFCE7),
    ),
    'Fruits': CategoryMeta(
      name: 'Fruits',
      emoji: '🍎',
      icon: Icons.apple_rounded,
      color: Color(0xFFE11D48),
      bgColor: Color(0xFFFFE4E6),
    ),
    'Pulses': CategoryMeta(
      name: 'Pulses',
      emoji: '🫘',
      icon: Icons.circle_outlined,
      color: Color(0xFF78350F),
      bgColor: Color(0xFFF5EBE1),
    ),
    'Spices': CategoryMeta(
      name: 'Spices',
      emoji: '🌶️',
      icon: Icons.whatshot_rounded,
      color: Color(0xFFEA580C),
      bgColor: Color(0xFFFFEDD5),
    ),
    'Snacks': CategoryMeta(
      name: 'Snacks',
      emoji: '🍪',
      icon: Icons.cookie_outlined,
      color: Color(0xFFD97706),
      bgColor: Color(0xFFFEF3C7),
    ),
    'Beverages': CategoryMeta(
      name: 'Beverages',
      emoji: '☕',
      icon: Icons.coffee_rounded,
      color: Color(0xFF6D28D9),
      bgColor: Color(0xFFEDE9FE),
    ),
    'Cleaning': CategoryMeta(
      name: 'Cleaning',
      emoji: '🧼',
      icon: Icons.cleaning_services_rounded,
      color: Color(0xFF0D9488),
      bgColor: Color(0xFFCCFBF1),
    ),
    'Personal care': CategoryMeta(
      name: 'Personal care',
      emoji: '🧴',
      icon: Icons.spa_rounded,
      color: Color(0xFFDB2777),
      bgColor: Color(0xFFFCE7F3),
    ),
    'Other': CategoryMeta(
      name: 'Other',
      emoji: '📦',
      icon: Icons.inventory_2_rounded,
      color: Color(0xFF475569),
      bgColor: Color(0xFFF1F5F9),
    ),
  };

  static CategoryMeta get(String category) =>
      all[category] ?? all['Other']!;
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        primaryContainer: AppColors.mintLight,
      ),
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.cardBorder, width: 1),
        ),
        margin: const EdgeInsets.symmetric(vertical: 6),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.cardBorder),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.accentMint, width: 1.8),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
    );
  }
}
