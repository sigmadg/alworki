import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../models/user_profile.dart';
import '../../../theme/app_colors.dart';
import '../../widgets/alworki_image.dart';

class PortfolioTab extends StatelessWidget {
  const PortfolioTab({
    super.key,
    required this.items,
    this.isOwnProfile = false,
    this.userName = '',
    this.avatarKey = 'users/user.jpg',
    this.userId,
    this.embeddedInScroll = false,
  });

  final List<PortfolioItem> items;
  final bool isOwnProfile;
  final String userName;
  final String avatarKey;
  final int? userId;
  final bool embeddedInScroll;

  @override
  Widget build(BuildContext context) {
    final actionRow = (isOwnProfile || items.isNotEmpty)
        ? Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                if (isOwnProfile)
                  FilledButton.icon(
                    onPressed: () => context.push('/publish-portfolio'),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Publicar'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.navBar,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                  ),
                const Spacer(),
                if (items.isNotEmpty)
                  TextButton.icon(
                    onPressed: () => context.push(
                      '/portfolio-feed',
                      extra: {'name': userName, 'avatar': avatarKey, 'userId': userId, 'items': items},
                    ),
                    icon: const Icon(Icons.view_agenda_outlined, size: 18),
                    label: const Text('Ver feed'),
                  ),
              ],
            ),
          )
        : const SizedBox.shrink();

    final grid = items.isEmpty
        ? Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.photo_library_outlined, size: 56, color: AppColors.textSecondary.withValues(alpha: 0.5)),
                const SizedBox(height: 12),
                const Text('Sin trabajos en portafolio'),
                if (isOwnProfile) ...[
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => context.push('/publish-portfolio'),
                    icon: const Icon(Icons.add),
                    label: const Text('Publicar nuevo trabajo'),
                    style: FilledButton.styleFrom(backgroundColor: AppColors.navBar),
                  ),
                ],
              ],
            ),
          )
        : GridView.builder(
            shrinkWrap: embeddedInScroll,
            physics: embeddedInScroll ? const NeverScrollableScrollPhysics() : null,
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
            ),
            itemCount: items.length,
            itemBuilder: (context, i) {
              final item = items[i];
              return GestureDetector(
                onTap: () => context.push(
                  '/portfolio-feed',
                  extra: {'name': userName, 'avatar': avatarKey, 'userId': userId, 'items': items},
                ),
                child: AlworkiImage(imageKey: item.imageKey, fit: BoxFit.cover),
              );
            },
          );

    if (embeddedInScroll) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [actionRow, grid],
      );
    }

    return Column(
      children: [
        actionRow,
        Expanded(child: grid),
      ],
    );
  }
}
