import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../services/social_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../widgets/alworki_image.dart';

class ContactRequestsScreen extends StatefulWidget {
  const ContactRequestsScreen({super.key});

  @override
  State<ContactRequestsScreen> createState() => _ContactRequestsScreenState();
}

class _ContactRequestsScreenState extends State<ContactRequestsScreen> {
  int? _expandedId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SocialService>().loadContactRequests();
    });
  }

  @override
  Widget build(BuildContext context) {
    final requests = context.watch<SocialService>().contactRequests;

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        title: Text('Solicitudes para contactar', style: AppTypography.titleSmall.copyWith(fontSize: 16)),
      ),
      body: requests.isEmpty
          ? Center(child: Text('No hay solicitudes pendientes', style: AppTypography.sectionSubtitle))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: requests.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final req = requests[i];
                final expanded = _expandedId == req.id;
                return Container(
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: expanded ? AppColors.navBar.withValues(alpha: 0.3) : AppColors.border),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        leading: AlworkiAvatar(avatarKey: req.avatarKey, radius: 24),
                        title: Text(req.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: req.subtitle.isNotEmpty ? Text(req.subtitle) : null,
                        trailing: Icon(expanded ? Icons.expand_less : Icons.expand_more),
                        onTap: () => setState(() => _expandedId = expanded ? null : req.id),
                      ),
                      if (expanded)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () async {
                                    final ok = await context.read<SocialService>().acceptContactRequest(req.id);
                                    if (context.mounted && ok) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('${req.name} aceptado')),
                                      );
                                    }
                                  },
                                  icon: Icon(Icons.check, color: AppColors.proximity.withValues(alpha: 0.9)),
                                  label: Text('Aceptar', style: TextStyle(color: AppColors.proximity.withValues(alpha: 0.95))),
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(color: AppColors.proximity.withValues(alpha: 0.5)),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () async {
                                    await context.read<SocialService>().rejectContactRequest(req.id);
                                  },
                                  icon: const Icon(Icons.close, color: AppColors.reportRed),
                                  label: const Text('Cancelar', style: TextStyle(color: AppColors.reportRed)),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: AppColors.reportRed),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
