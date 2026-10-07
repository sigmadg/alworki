import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/feed_post.dart';
import '../../services/catalog_service.dart';
import '../../services/exchange_repository.dart';
import '../../theme/app_colors.dart';
import '../../utils/share_actions.dart';
import '../profile/widgets/review_action_flows.dart';
import '../widgets/alworki_image.dart';

class FeedPostCard extends StatelessWidget {
  const FeedPostCard({super.key, required this.post});

  final FeedPost post;

  @override
  Widget build(BuildContext context) {
    final catalog = context.read<CatalogService>();
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: AlworkiAvatar(avatarKey: post.user.avatar, radius: 20),
            title: GestureDetector(
              onTap: () => context.push(
                '/user/${post.user.id}?name=${Uri.encodeComponent(post.user.name)}&avatar=${Uri.encodeComponent(post.user.avatar)}',
              ),
              child: Row(
                children: [
                  Flexible(child: Text(post.user.name, overflow: TextOverflow.ellipsis)),
                  if (post.user.verified) ...[
                    const SizedBox(width: 4),
                    Icon(Icons.verified, size: 16, color: Theme.of(context).colorScheme.primary),
                  ],
                ],
              ),
            ),
            subtitle: Row(
              children: [
                const Icon(Icons.place, size: 14),
                const SizedBox(width: 2),
                Expanded(child: Text(post.location, overflow: TextOverflow.ellipsis)),
                if (post.recommended) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.trustButton.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Para ti',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.trustButton),
                    ),
                  ),
                ],
              ],
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (v) async {
                if (v == 'share') {
                  await shareFeedPost(context, post);
                } else if (v == 'report') {
                  showReportProblemFlow(context, providerId: post.user.id);
                } else if (v == 'match') {
                  final req = await context.read<ExchangeRepository>().createFromPost(
                        postId: post.id,
                        cardTitle: post.cardTitle,
                        authorName: post.user.name,
                        cardId: post.cardId,
                        targetUserId: post.user.id,
                      );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          req != null
                              ? 'Solicitud de coincidencia creada'
                              : context.read<ExchangeRepository>().error ?? 'No se pudo crear la solicitud',
                        ),
                      ),
                    );
                  }
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'share', child: Text('Compartir')),
                PopupMenuItem(value: 'match', child: Text('Solicitud de coincidencia')),
                PopupMenuItem(value: 'report', child: Text('Reportar')),
              ],
            ),
          ),
          AlworkiImage(imageKey: post.imageKey, height: 280),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(post.liked ? Icons.favorite : Icons.favorite_border, color: post.liked ? Colors.red : null),
                  onPressed: () => catalog.toggleLike(post.id),
                ),
                Text('${post.likes}'),
                const SizedBox(width: 16),
                InkWell(
                  onTap: () => showCommentFlow(context, providerId: post.user.id),
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.chat_bubble_outline, size: 22),
                        const SizedBox(width: 4),
                        Text('${post.comments}'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                InkWell(
                  onTap: () => shareFeedPost(context, post),
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.share_outlined, size: 22),
                        const SizedBox(width: 4),
                        Text('${(post.likes / 40).round()}'),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(post.saved ? Icons.bookmark : Icons.bookmark_border),
                  onPressed: () => catalog.toggleSave(post.id),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: RichText(
              text: TextSpan(
                style: DefaultTextStyle.of(context).style,
                children: [
                  TextSpan(text: '${post.user.name} ', style: const TextStyle(fontWeight: FontWeight.w600)),
                  TextSpan(text: post.description),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.swap_horiz,
                          size: 18,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '${post.cost} ${post.costType} · ${post.cardTitle}',
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                TextButton(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () => catalog.toggleFollow(post.id),
                  child: Text(post.user.following ? 'Siguiendo' : 'Seguir'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
