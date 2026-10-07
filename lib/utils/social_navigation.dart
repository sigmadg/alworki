import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../services/social_service.dart';

/// Abre el chat con un usuario; crea el hilo si aún no existe.
Future<void> openChatWithPeer(
  BuildContext context, {
  required int peerId,
  required String name,
  String avatarKey = 'users/user.jpg',
  String profession = '',
}) async {
  final threadId = await context.read<SocialService>().openThreadWithPeer(
        peerId: peerId,
        name: name,
        avatarKey: avatarKey,
        profession: profession,
      );
  if (!context.mounted) return;
  if (threadId != null) {
    context.push('/messages/$threadId');
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No se pudo abrir la conversación')),
    );
  }
}
