import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/feed_post.dart';
import '../models/user_profile.dart';
import '../services/profile_actions_service.dart';

Future<void> copyShareLink(
  BuildContext context,
  String url, {
  String message = 'Enlace copiado al portapapeles',
}) async {
  await Clipboard.setData(ClipboardData(text: url));
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}

Future<void> shareFeedPost(BuildContext context, FeedPost post) async {
  await copyShareLink(context, 'https://alworki.com/post/${post.id}');
}

Future<void> sharePortfolioItem(
  BuildContext context, {
  int? userId,
  required PortfolioItem item,
}) async {
  var url = 'https://alworki.com/portfolio/${item.id}';
  if (userId != null) {
    try {
      url = await context.read<ProfileActionsService>().shareProfile(userId);
    } catch (_) {}
  }
  await copyShareLink(context, url);
}
