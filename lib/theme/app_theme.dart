import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFFFBC450);
  static const Color primaryLight = Color(0xFFFFE6A6);
  static const Color primarySurface = Color(0xFFFFF8E8);

  static const Color backgroundTop = Color(0xFFFFFFFF);
  static const Color backgroundBottom = Color(0xFFFCE4B0);

  static const Color textPrimary = Color(0xFF09090B);
  static const Color textSecondary = Color(0xFF52525B);
  static const Color textTertiary = Color(0xFFA1A1AA);

  static const Color cardBackground = Color(0xFFF4F4F5);
  static const Color cardBorder = Color(0xFFE4E4E7);

  static const Color priorityHigh = Color(0xFFFBC450);
  static const Color priorityMedium = Color(0xFF09090B);
  static const Color priorityLow = Color(0xFFA1A1AA);

  static const Color labelKuliah = Color(0xFF6F9A7E);
  static const Color labelKerja = Color(0xFF6B8FB5);
  static const Color labelSkripsi = Color(0xFFFF9800);

  static const Color navBarBackground = Colors.white;
  static const Color navBarActive = Colors.black;
  static const Color navBarInactive = Color(0xFF9E9EA8);

  static const Color progressTrack = Color(0xFFE4E4E7);
  static const Color progressFill = Color(0xFFFBC450);
}

class AppTextStyles {
  static const TextStyle appTitle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w900,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
  );

  static const TextStyle appTitleLight = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
  );

  static const TextStyle sectionHeader = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
    letterSpacing: 1.2,
  );

  static const TextStyle sectionCount = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );

  static const TextStyle taskTitle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  static const TextStyle taskMeta = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  static const TextStyle priorityLabel = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle progressLabel = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  static const TextStyle progressValue = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );

  static const TextStyle inputHint = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textTertiary,
  );

  static const TextStyle expandableSection = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
    letterSpacing: 1.2,
  );

  static const TextStyle buttonText = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: Colors.white,
  );
}

class AppTheme {
  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Inter',
      scaffoldBackgroundColor: Colors.transparent,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
      ),
    );
  }
}
