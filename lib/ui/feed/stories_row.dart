import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/story_item.dart';
import '../../services/catalog_service.dart';
import '../../state/auth_controller.dart';
import '../widgets/alworki_image.dart';
import '../widgets/app_modal.dart';

class StoriesRow extends StatelessWidget {
  const StoriesRow({super.key});

  @override
  Widget build(BuildContext context) {
    final stories = context.watch<CatalogService>().stories;
    final canPost = context.watch<AuthController>().isLoggedIn && !context.watch<AuthController>().isGuest;
    return SizedBox(
      height: 108,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: stories.length + 1,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          if (i == 0) {
            return _AddStoryAvatar(
              onTap: () => context.push(canPost ? '/create-story' : '/login'),
            );
          }
          return _StoryAvatar(story: stories[i - 1]);
        },
      ),
    );
  }
}

class _AddStoryAvatar extends StatelessWidget {
  const _AddStoryAvatar({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: const SizedBox(
        width: 72,
        child: Column(
          children: [
            CircleAvatar(
              radius: 31,
              backgroundColor: Color(0x332196F3),
              child: Icon(Icons.add, color: Color(0xFF1E88E5)),
            ),
            SizedBox(height: 4),
            Text('Tu historia', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

class _StoryAvatar extends StatelessWidget {
  const _StoryAvatar({required this.story});
  final StoryItem story;

  @override
  Widget build(BuildContext context) {
    final ring = story.viewed ? Colors.grey.shade400 : Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: () {
        context.read<CatalogService>().markStoryViewed(story.id);
        showAppDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(story.user.name),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: AlworkiImage(imageKey: story.imageKey, height: 160),
                ),
                const SizedBox(height: 12),
                Text(story.caption),
                const SizedBox(height: 8),
                Text('Favor: ${story.cardTitle}', style: Theme.of(ctx).textTheme.labelLarge),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cerrar')),
            ],
          ),
        );
      },
      child: SizedBox(
        width: 72,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: ring, width: 2)),
              child: AlworkiAvatar(avatarKey: story.user.avatar, radius: 28),
            ),
            const SizedBox(height: 4),
            Text(
              story.user.name.split(' ').first,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
