import 'package:flutter/material.dart';

import '../../models/user_profile.dart';
import '../../theme/app_colors.dart';
import '../../utils/share_actions.dart';
import '../profile/widgets/review_action_flows.dart';
import '../widgets/alworki_image.dart';
import '../widgets/app_modal.dart';

/// Vista feed del portafolio (Figma: posts con likes, comentarios, compartir).
class PortfolioFeedScreen extends StatelessWidget {
  const PortfolioFeedScreen({
    super.key,
    required this.userName,
    required this.avatarKey,
    required this.items,
    this.userId,
  });

  final String userName;
  final String avatarKey;
  final List<PortfolioItem> items;
  final int? userId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(
        title: const Text('Portafolio', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: items.isEmpty
          ? const Center(child: Text('Sin publicaciones'))
          : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 12),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, i) => _FeedCard(
                userName: userName.isNotEmpty ? userName : 'Beth Williams',
                avatarKey: avatarKey,
                userId: userId,
                item: items[i],
              ),
            ),
    );
  }
}

class _FeedCard extends StatefulWidget {
  const _FeedCard({
    required this.userName,
    required this.avatarKey,
    required this.item,
    this.userId,
  });

  final String userName;
  final String avatarKey;
  final PortfolioItem item;
  final int? userId;

  @override
  State<_FeedCard> createState() => _FeedCardState();
}

class _FeedCardState extends State<_FeedCard> {
  bool _liked = false;
  int _shares = 0;

  String _formatLikes(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(0)}k Likes';
    return '$n Likes';
  }

  String _formatCount(int n) => n >= 1000 ? '${(n / 1000).toStringAsFixed(0)}k' : '$n';

  void _showMenu() {
    showAppBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.share_outlined),
              title: const Text('Compartir'),
              onTap: () {
                Navigator.pop(ctx);
                sharePortfolioItem(context, userId: widget.userId, item: widget.item);
                setState(() => _shares++);
              },
            ),
            if (widget.userId != null)
              ListTile(
                leading: const Icon(Icons.flag_outlined),
                title: const Text('Reportar'),
                onTap: () {
                  Navigator.pop(ctx);
                  showReportProblemFlow(context, providerId: widget.userId);
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final likes = item.likes > 0 ? item.likes : 10000;
    final comments = item.comments > 0 ? item.comments : 100;
    final shares = (item.shares > 0 ? item.shares : 35) + _shares;
    final displayLikes = _liked ? likes + 1 : likes;

    return ColoredBox(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 8, 8),
            child: Row(
              children: [
                AlworkiAvatar(avatarKey: widget.avatarKey, radius: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      Text(
                        item.location.isNotEmpty ? item.location : 'México',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_horiz),
                  onPressed: _showMenu,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              item.description.isNotEmpty ? item.description : item.title,
              style: const TextStyle(height: 1.35),
            ),
          ),
          const SizedBox(height: 8),
          AlworkiImage(imageKey: item.imageKey, height: 280, width: double.infinity, fit: BoxFit.cover),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                _Action(
                  icon: _liked ? Icons.favorite : Icons.favorite_border,
                  label: _formatLikes(displayLikes),
                  color: _liked ? Colors.red : AppColors.textSecondary,
                  onTap: () => setState(() => _liked = !_liked),
                ),
                const SizedBox(width: 20),
                _Action(
                  icon: Icons.chat_bubble_outline,
                  label: _formatCount(comments),
                  onTap: () => showCommentFlow(context, providerId: widget.userId),
                ),
                const SizedBox(width: 20),
                _Action(
                  icon: Icons.share_outlined,
                  label: _formatCount(shares),
                  onTap: () {
                    setState(() => _shares++);
                    sharePortfolioItem(context, userId: widget.userId, item: item);
                  },
                ),
                const Spacer(),
                if (item.profession.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.navBar.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      item.profession,
                      style: const TextStyle(
                        color: AppColors.navBar,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                if (item.tag.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.localBadge.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      item.tag,
                      style: const TextStyle(
                        color: AppColors.localBadge,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                if (item.priceMxn > 0) ...[
                  const SizedBox(width: 8),
                  Text(
                    '${item.priceMxn}\$',
                    style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.navBar),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({
    required this.icon,
    required this.label,
    this.color = AppColors.textSecondary,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: color, fontSize: 13)),
        ],
      ),
    );
  }
}
