import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/story_item.dart';
import '../../services/catalog_service.dart';
import '../../theme/app_colors.dart';
import '../widgets/alworki_image.dart';
import '../widgets/app_section_header.dart';

class SuggestionsRow extends StatelessWidget {
  const SuggestionsRow({super.key});

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogService>();
    final stories = catalog.suggestedStories;
    if (stories.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppSectionHeader(
          title: 'Sugerencias para ti',
          subtitle: 'Perfiles que podrían interesarte según tu actividad',
          padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
        ),
        SizedBox(
          height: 200,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: stories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, i) => _SuggestionCard(story: stories[i]),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  const _SuggestionCard({required this.story});

  final StoryItem story;

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogService>();
    final trusted = catalog.isTrusted(story.user.id);

    return GestureDetector(
      onTap: () => context.push(
        '/user/${story.user.id}?name=${Uri.encodeComponent(story.user.name)}&avatar=${Uri.encodeComponent(story.user.avatar)}',
      ),
      child: Container(
        width: 140,
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  AlworkiImage(imageKey: story.imageKey, fit: BoxFit.cover),
                  if (story.user.verified)
                    const Positioned(
                      top: 8,
                      right: 8,
                      child: Icon(Icons.verified, color: Colors.white, size: 18),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  Row(
                    children: [
                      AlworkiAvatar(avatarKey: story.user.avatar, radius: 14),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          story.user.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  if (story.cardTitle.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      story.cardTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                    ),
                  ],
                  const SizedBox(height: 6),
                  SizedBox(
                    width: double.infinity,
                    height: 28,
                    child: FilledButton(
                      onPressed: () => catalog.toggleTrust(story.user.id),
                      style: FilledButton.styleFrom(
                        backgroundColor: trusted ? AppColors.textSecondary : AppColors.trustButton,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text(
                        trusted ? 'Confías' : 'Confío',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
