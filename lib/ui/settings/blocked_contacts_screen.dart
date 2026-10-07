import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../services/social_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../widgets/alworki_image.dart';

class BlockedContactsScreen extends StatefulWidget {
  const BlockedContactsScreen({super.key});

  @override
  State<BlockedContactsScreen> createState() => _BlockedContactsScreenState();
}

class _BlockedContactsScreenState extends State<BlockedContactsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SocialService>().loadBlockedContacts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final blocked = context.watch<SocialService>().blockedContacts;

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        title: Text('Contactos bloqueados', style: AppTypography.titleSmall.copyWith(fontSize: 16)),
      ),
      body: blocked.isEmpty
          ? Center(child: Text('No tienes contactos bloqueados', style: AppTypography.sectionSubtitle))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: blocked.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final contact = blocked[i];
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      AlworkiAvatar(avatarKey: contact.avatarKey, radius: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(contact.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                      ),
                      OutlinedButton(
                        onPressed: () async {
                          final ok = await context.read<SocialService>().unblockContact(contact.id);
                          if (context.mounted && ok) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('${contact.name} desbloqueado')),
                            );
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.localBadge,
                          side: const BorderSide(color: AppColors.localBadge),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                        child: const Text('Desbloquear'),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
