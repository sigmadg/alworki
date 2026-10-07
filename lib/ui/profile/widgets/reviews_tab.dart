import 'package:flutter/material.dart';

import '../../../models/user_profile.dart';
import '../../../theme/app_colors.dart';
import '../../widgets/alworki_image.dart';
import 'review_action_flows.dart';

class ReviewsTab extends StatelessWidget {
  const ReviewsTab({
    super.key,
    required this.reviews,
    this.providerId,
    this.showActions = true,
    this.embeddedInScroll = false,
  });

  final List<ProfileReview> reviews;
  final int? providerId;
  final bool showActions;
  final bool embeddedInScroll;

  @override
  Widget build(BuildContext context) {
    if (reviews.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: Text('Aún no hay reseñas')),
      );
    }

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...reviews.map((r) => Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: _ReviewCard(review: r),
            )),
        if (showActions)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                OutlinedButton(
                  onPressed: () => showReportProblemFlow(context, providerId: providerId),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.commentBlue,
                    side: const BorderSide(color: AppColors.commentBlue, width: 1.5),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: const Text('Reporte'),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: () => showCommentFlow(context, providerId: providerId),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.commentBlue,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: const Text('Reseña'),
                ),
              ],
            ),
          ),
      ],
    );

    if (embeddedInScroll) return content;

    return ListView(
      padding: const EdgeInsets.only(top: 16),
      children: [
        ...reviews.map((r) => Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: _ReviewCard(review: r),
            )),
        if (showActions)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                OutlinedButton(
                  onPressed: () => showReportProblemFlow(context, providerId: providerId),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.commentBlue,
                    side: const BorderSide(color: AppColors.commentBlue, width: 1.5),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: const Text('Reporte'),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: () => showCommentFlow(context, providerId: providerId),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.commentBlue,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: const Text('Reseña'),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review});
  final ProfileReview review;

  @override
  Widget build(BuildContext context) {
    final title = review.serviceTitle ?? review.text.split('—').first.trim();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AlworkiAvatar(avatarKey: review.user.avatar, radius: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(review.user.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    Row(
                      children: List.generate(
                        5,
                        (j) => Icon(
                          j < review.rating ? Icons.star : Icons.star_border,
                          size: 16,
                          color: Colors.amber.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (title.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          ],
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.trustButton.withValues(alpha: 0.25)),
              borderRadius: BorderRadius.circular(12),
              color: AppColors.trustButton.withValues(alpha: 0.06),
            ),
            child: Text(review.text, style: const TextStyle(height: 1.4, fontSize: 14)),
          ),
        ],
      ),
    );
  }
}
