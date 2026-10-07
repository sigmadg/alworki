import 'package:flutter/material.dart';

/// Paleta oscura premium (referencia UI — tonos púrpura/carbón).
abstract final class AppColors {
  // Base
  static const background = Color(0xFF1E1E2A);
  static const surface = Color(0xFF302E3B);
  static const surfaceElevated = Color(0xFF44404D);
  static const surfaceMuted = Color(0xFF4B4B5B);
  static const textMuted = Color(0xFF797993);

  // Semánticos (mapeo para el resto de la app)
  static const scaffold = background;
  static const card = surface;
  static const navBar = surface;
  static const navBarDark = background;
  static const border = surfaceMuted;

  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = textMuted;

  // Acentos
  static const trustButton = surfaceElevated;
  static const fabStart = surfaceElevated;
  static const fabEnd = surfaceMuted;
  static const proximity = Color(0xFF6BCB94);
  static const localBadge = Color(0xFF8B9DC3);
  static const remoteBadge = Color(0xFF7BA88C);
  static const notificationBg = surface;

  // Estados
  static const deleteRed = Color(0xFFE87070);
  static const reportRed = Color(0xFFFF6B6B);
  static const commentBlue = Color(0xFF8B9DC3);
  static const stripePay = Color(0xFF5C3D4A);
  static const commissionOrange = Color(0xFFE8A54B);

  static const fabGradient = LinearGradient(
    colors: [surfaceElevated, surfaceMuted],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const heroGradient = LinearGradient(
    colors: [surface, background],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const notificationGradient = LinearGradient(
    colors: [surface, background],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const drawerGradient = LinearGradient(
    colors: [surface, background],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
