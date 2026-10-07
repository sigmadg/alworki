import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../services/social_service.dart';
import '../../theme/app_colors.dart';
import '../widgets/alworki_image.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SocialService>().loadNotifications();
    });
  }

  Future<void> _delete(int id) async {
    await context.read<SocialService>().removeNotification(id);
  }

  void _openNotification(BuildContext context, AppNotification notification) {
    final msg = notification.message.toLowerCase();
    if (msg.contains('contactar') || msg.contains('contacto')) {
      context.push('/contacts?tab=1');
    } else if (msg.contains('publicó') || msg.contains('favor') || msg.contains('intercambio')) {
      context.push('/exchange');
    } else if (msg.contains('cotiz') || msg.contains('mensaje') || msg.contains('chat')) {
      context.push('/messages');
    } else {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final social = context.watch<SocialService>();
    final items = social.notifications;
    final recent = items.where((n) => n.isRecent).toList();
    final earlier = items.where((n) => !n.isRecent).toList();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Notificaciones', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text(
              'Actividad de tu cuenta y la comunidad',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
                color: AppColors.textSecondary.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.card,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.notificationGradient),
        child: social.isLoading && items.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : items.isEmpty
                ? const Center(child: Text('No hay notificaciones'))
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      ...recent.map(
                        (n) => _NotificationTile(
                          notification: n,
                          onDelete: () => _delete(n.id),
                          onTap: () => _openNotification(context, n),
                        ),
                      ),
                      if (earlier.isNotEmpty) ...[
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            'Anteriores',
                            style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                          ),
                        ),
                        ...earlier.map(
                          (n) => _NotificationTile(
                            notification: n,
                            onDelete: () => _delete(n.id),
                            onTap: () => _openNotification(context, n),
                          ),
                        ),
                      ],
                    ],
                  ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.notification,
    required this.onDelete,
    required this.onTap,
  });

  final AppNotification notification;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  void _showMenu(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.open_in_new),
              title: const Text('Abrir'),
              onTap: () {
                Navigator.pop(ctx);
                onTap();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: AppColors.deleteRed),
              title: const Text('Eliminar', style: TextStyle(color: AppColors.deleteRed)),
              onTap: () {
                Navigator.pop(ctx);
                onDelete();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.deleteRed,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete_outline, color: Colors.white),
            Text('Borrar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      onDismissed: (_) => onDelete(),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.notificationBg.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AlworkiAvatar(avatarKey: notification.avatarKey, radius: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.message,
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, height: 1.4),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        notification.timeAgo,
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_horiz, color: AppColors.textSecondary),
                  onPressed: () => _showMenu(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
