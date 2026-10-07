import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// Paleta auth alineada con el tema oscuro principal.
abstract final class AuthColors {
  static const gradientTop = AppColors.background;
  static const gradientBottom = AppColors.surface;
  static const accent = AppColors.surfaceElevated;
  static const accentDark = AppColors.surfaceMuted;
  static const textPrimary = AppColors.textPrimary;
  static const textMuted = Color(0xB3FFFFFF);
  static const underline = Color(0x66FFFFFF);
  static const error = AppColors.deleteRed;
  static const errorBg = Color(0x33E87070);

  static const backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [gradientTop, gradientBottom],
  );
}
