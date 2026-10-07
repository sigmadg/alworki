import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../services/catalog_service.dart';
import '../../state/auth_controller.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import 'alworki_image.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({
    super.key,
    this.showGreeting = true,
    this.title,
    this.subtitle,
    this.onMenuTap,
    this.showNotifications = true,
  });

  final bool showGreeting;
  final String? title;
  final String? subtitle;
  final VoidCallback? onMenuTap;
  final bool showNotifications;

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Buenos días';
    if (h < 19) return 'Buenas tardes';
    return 'Buenas noches';
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<CatalogService>().profile;
    final auth = context.watch<AuthController>();
    final displayTitle = title ?? 'Alworki';
    final isHome = title == null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showGreeting)
            Text(_greeting(), style: AppTypography.bodySmall),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.menu, color: AppColors.textPrimary),
                onPressed: onMenuTap ?? () => Scaffold.of(context).openDrawer(),
                tooltip: 'Menú',
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      displayTitle,
                      textAlign: TextAlign.center,
                      style: AppTypography.titleLarge.copyWith(fontSize: isHome ? 22 : 20),
                    ),
                    if (isHome)
                      Text(
                        'Intercambio de favores',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.trustButton,
                          fontWeight: FontWeight.w500,
                        ),
                      )
                    else if (subtitle != null)
                      Text(subtitle!, style: AppTypography.caption),
                  ],
                ),
              ),
              if (showNotifications)
                IconButton(
                  icon: const Icon(Icons.notifications_outlined, color: AppColors.textPrimary),
                  onPressed: () => context.push('/notifications'),
                  tooltip: 'Notificaciones',
                )
              else
                const SizedBox(width: 48),
              GestureDetector(
                onTap: () => context.go('/profile'),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    AlworkiAvatar(
                      avatarKey: auth.user?.isGuest == true ? 'users/user.jpg' : profile.avatar,
                      radius: 18,
                    ),
                    if (profile.localAvailable)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: AppColors.proximity,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
            ],
          ),
        ],
      ),
    );
  }
}
