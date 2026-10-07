import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../widgets/app_screen_insets.dart';

/// Barra superior unificada para las pestañas del shell principal.
class ShellTabHeader extends StatelessWidget {
  const ShellTabHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.onMenuTap,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final VoidCallback? onMenuTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 6, 8, 12),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.menu, color: AppColors.textPrimary),
              onPressed: onMenuTap ?? () => Scaffold.of(context).openDrawer(),
              tooltip: 'Menú principal',
            ),
            Expanded(
              child: Column(
                children: [
                  Text(title, textAlign: TextAlign.center, style: AppTypography.titleLarge.copyWith(fontSize: 18)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      textAlign: TextAlign.center,
                      style: AppTypography.caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            trailing ?? const SizedBox(width: 48),
          ],
        ),
      ),
    );
  }
}

/// Espacio inferior para que el contenido no quede bajo la barra de navegación.
double shellBottomInset(BuildContext context) => AppScreenInsets.shellBottom(context);
