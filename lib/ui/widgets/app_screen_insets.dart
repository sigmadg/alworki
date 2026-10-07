import 'package:flutter/material.dart';

/// Márgenes seguros para que el contenido no quede pegado o cortado en los bordes.
abstract final class AppScreenInsets {
  static const double horizontal = 10;
  static const double bottomNavClearance = 88;

  /// Padding inferior para listas dentro del shell (barra + gestos).
  static double shellBottom(BuildContext context) =>
      MediaQuery.paddingOf(context).bottom + bottomNavClearance;

  /// Envuelve el contenido del shell principal (respeta barra de estado y laterales).
  static Widget shellBody({required Widget child}) {
    return SafeArea(
      bottom: false,
      minimum: const EdgeInsets.symmetric(horizontal: horizontal),
      child: child,
    );
  }

  /// Envuelve el cuerpo de pantallas secundarias (con AppBar).
  static Widget secondaryBody({required Widget child}) {
    return SafeArea(
      top: false,
      bottom: false,
      minimum: const EdgeInsets.symmetric(horizontal: horizontal),
      child: child,
    );
  }
}
