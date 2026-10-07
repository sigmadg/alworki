import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import 'app_screen_insets.dart';

/// Scaffold estándar para pantallas secundarias (fuera del shell principal).
class SecondaryScreenScaffold extends StatelessWidget {
  const SecondaryScreenScaffold({
    super.key,
    required this.title,
    this.subtitle,
    required this.body,
    this.floatingActionButton,
    this.actions,
  });

  final String title;
  final String? subtitle;
  final Widget body;
  final Widget? floatingActionButton;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTypography.titleSmall.copyWith(fontSize: 17)),
            if (subtitle != null)
              Text(
                subtitle!,
                style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
              ),
          ],
        ),
        actions: actions,
      ),
      body: AppScreenInsets.secondaryBody(child: body),
      floatingActionButton: floatingActionButton,
    );
  }
}
