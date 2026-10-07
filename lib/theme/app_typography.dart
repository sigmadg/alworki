import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Estilos de texto centralizados para consistencia en toda la app.
abstract final class AppTypography {
  static const display = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    height: 1.2,
  );

  static const titleLarge = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static const titleMedium = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static const titleSmall = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const bodyLarge = TextStyle(
    fontSize: 15,
    color: AppColors.textPrimary,
    height: 1.45,
  );

  static const bodyMedium = TextStyle(
    fontSize: 14,
    color: AppColors.textPrimary,
    height: 1.4,
  );

  static const bodySmall = TextStyle(
    fontSize: 13,
    color: AppColors.textSecondary,
    height: 1.35,
  );

  static const label = TextStyle(
    fontSize: 12,
    color: AppColors.textSecondary,
    height: 1.3,
  );

  static const caption = TextStyle(
    fontSize: 11,
    color: AppColors.textSecondary,
  );

  static const navLabel = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w500,
  );

  static const sectionSubtitle = TextStyle(
    fontSize: 13,
    color: AppColors.textSecondary,
    height: 1.35,
  );
}
