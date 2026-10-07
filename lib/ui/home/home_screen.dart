import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../services/catalog_service.dart';
import '../../state/auth_controller.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../feed/feed_post_card.dart';
import '../feed/project_feed_card.dart';
import '../feed/stories_row.dart';
import '../feed/suggestions_row.dart';
import '../home/home_hero_banner.dart';
import '../widgets/app_section_header.dart';
import '../widgets/app_screen_insets.dart';
import '../widgets/home_header.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogService>();
    final isGuest = context.watch<AuthController>().isGuest;

    if (catalog.isLoading && catalog.posts.isEmpty) {
      return const ColoredBox(
        color: AppColors.scaffold,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return ColoredBox(
      color: AppColors.scaffold,
      child: RefreshIndicator(
        onRefresh: catalog.refresh,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: HomeHeader(onMenuTap: () => Scaffold.of(context).openDrawer()),
            ),
            if (isGuest)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Material(
                    color: AppColors.localBadge.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => context.go('/login'),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        child: Row(
                          children: [
                            Icon(Icons.person_outline, color: AppColors.localBadge.withValues(alpha: 0.9)),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Text(
                                'Modo invitado — regístrate para guardar tu perfil y cotizar servicios.',
                                style: AppTypography.label,
                              ),
                            ),
                            Icon(Icons.chevron_right, color: AppColors.textSecondary.withValues(alpha: 0.8)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            const SliverToBoxAdapter(child: StoriesRow()),
            const SliverToBoxAdapter(child: HomeHeroBanner()),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => context.go('/categories'),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.trustButton.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.grid_view_rounded, color: AppColors.trustButton, size: 22),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Explorar categorías', style: AppTypography.titleSmall),
                                SizedBox(height: 2),
                                Text(
                                  'Plomería, limpieza, educación y más',
                                  style: AppTypography.caption,
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right, color: AppColors.textSecondary.withValues(alpha: 0.6)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SuggestionsRow()),
            const SliverToBoxAdapter(
              child: AppSectionHeader(
                title: 'Proyectos y favores',
                subtitle: 'Feed tipo Instagram: profesionales, intercambios y proyectos',
                padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              ),
            ),
            if (catalog.homeFeed.isEmpty)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.forum_outlined, size: 48, color: AppColors.textSecondary),
                        SizedBox(height: 12),
                        Text(
                          'Aún no hay publicaciones',
                          style: AppTypography.titleSmall,
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Sé el primero en compartir un favor o proyecto con la comunidad',
                          style: AppTypography.sectionSubtitle,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final entry = catalog.homeFeed[i];
                    if (entry.isProject) {
                      return ProjectFeedCard(project: entry.project!);
                    }
                    return FeedPostCard(post: entry.post!);
                  },
                  childCount: catalog.homeFeed.length,
                ),
              ),
            SliverToBoxAdapter(child: SizedBox(height: AppScreenInsets.shellBottom(context))),
          ],
        ),
      ),
    );
  }
}
