import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../services/social_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../widgets/alworki_image.dart';
import '../widgets/secondary_screen_scaffold.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  int? _expandedRequestId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: widget.initialTab.clamp(0, 1));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final social = context.read<SocialService>();
      social.loadContacts();
      social.loadContactRequests();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final social = context.watch<SocialService>();
    final pendingCount = social.contactRequests.length;

    return SecondaryScreenScaffold(
      title: 'Contactos',
      subtitle: 'Tu red de confianza en Alworki',
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.navBar,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.navBar,
              labelStyle: AppTypography.titleSmall.copyWith(fontSize: 14),
              tabs: [
                const Tab(text: 'Mis contactos'),
                Tab(text: pendingCount > 0 ? 'Solicitudes ($pendingCount)' : 'Solicitudes'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _ContactsList(
                  loading: social.isLoading && social.contacts.isEmpty,
                  contacts: social.contacts,
                ),
                _RequestsList(
                  requests: social.contactRequests,
                  expandedId: _expandedRequestId,
                  onToggle: (id) => setState(() {
                    _expandedRequestId = _expandedRequestId == id ? null : id;
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactsList extends StatelessWidget {
  const _ContactsList({required this.loading, required this.contacts});

  final bool loading;
  final List<ContactItem> contacts;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (contacts.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: AppColors.textSecondary.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            Text('Sin contactos aún', style: AppTypography.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Cuando aceptes solicitudes o chatees con alguien, aparecerá aquí.',
              style: AppTypography.sectionSubtitle,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: contacts.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final contact = contacts[i];
        return Material(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              if (contact.threadId != null) {
                context.push('/messages/${contact.threadId}');
              } else if (contact.peerId != null) {
                context.push('/user/${contact.peerId}');
              }
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  AlworkiAvatar(avatarKey: contact.avatarKey, radius: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(contact.name, style: AppTypography.titleSmall.copyWith(fontSize: 15)),
                        if (contact.profession.isNotEmpty)
                          Text(contact.profession, style: AppTypography.caption),
                        if (contact.lastMessage.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            contact.lastMessage,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.bodySmall,
                          ),
                        ],
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (contact.time.isNotEmpty)
                        Text(contact.time, style: AppTypography.caption),
                      const SizedBox(height: 6),
                      Icon(
                        contact.threadId != null ? Icons.chat_bubble_outline : Icons.person_outline,
                        size: 18,
                        color: AppColors.navBar,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _RequestsList extends StatelessWidget {
  const _RequestsList({
    required this.requests,
    required this.expandedId,
    required this.onToggle,
  });

  final List<ContactRequest> requests;
  final int? expandedId;
  final ValueChanged<int> onToggle;

  @override
  Widget build(BuildContext context) {
    if (requests.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'No hay solicitudes pendientes',
            style: AppTypography.sectionSubtitle,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: requests.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final req = requests[i];
        final expanded = expandedId == req.id;
        return Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: expanded ? AppColors.navBar.withValues(alpha: 0.4) : AppColors.border,
            ),
          ),
          child: Column(
            children: [
              ListTile(
                leading: AlworkiAvatar(avatarKey: req.avatarKey, radius: 24),
                title: Text(req.name, style: AppTypography.titleSmall.copyWith(fontSize: 15)),
                subtitle: req.subtitle.isNotEmpty ? Text(req.subtitle, style: AppTypography.caption) : null,
                trailing: Icon(expanded ? Icons.expand_less : Icons.expand_more, color: AppColors.textSecondary),
                onTap: () => onToggle(req.id),
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
                              await context.read<SocialService>().loadContacts();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('${req.name} agregado a tus contactos')),
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
                          label: const Text('Rechazar', style: TextStyle(color: AppColors.reportRed)),
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
    );
  }
}
