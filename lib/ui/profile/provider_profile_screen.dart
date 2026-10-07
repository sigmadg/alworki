import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../data/provider_demo_data.dart';
import '../../models/user_profile.dart';
import '../../services/profile_actions_service.dart';
import '../../services/social_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../utils/social_navigation.dart';
import '../widgets/alworki_image.dart';
import '../widgets/shell_tab_header.dart';
import 'widgets/own_profile_header.dart';
import 'widgets/own_skills_tab.dart';
import 'widgets/verify_account_banner.dart';
import '../auth/verify_identity_screen.dart';
import 'widgets/booking_tab.dart';
import 'widgets/portfolio_tab.dart';
import 'widgets/reviews_tab.dart';
import 'widgets/review_action_flows.dart';
import '../settings/settings_drawer.dart';
import '../widgets/app_modal.dart';

class ProviderProfileScreen extends StatefulWidget {
  const ProviderProfileScreen({
    super.key,
    required this.profile,
    this.isOwnProfile = false,
    this.showBackButton = false,
    this.showProfileChrome = true,
    this.initialTab = 0,
    this.topBar,
  });

  final UserProfile profile;
  final bool isOwnProfile;
  final bool showBackButton;
  final bool showProfileChrome;
  final int initialTab;
  final Widget? topBar;

  @override
  State<ProviderProfileScreen> createState() => _ProviderProfileScreenState();
}

class _ProviderProfileScreenState extends State<ProviderProfileScreen> {
  late int _tabIndex;
  bool _isContact = false;
  bool _contactPending = false;
  bool _contactLoading = false;

  UserProfile get _profile {
    if (widget.isOwnProfile) return widget.profile;
    return ProviderDemoData.enrichedProfile(
      widget.profile,
      forceVerified: widget.profile.verified ? true : null,
    );
  }

  @override
  void initState() {
    super.initState();
    _tabIndex = widget.initialTab.clamp(0, 2);
    if (!widget.isOwnProfile) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadContactState());
    }
  }

  Future<void> _loadContactState() async {
    final social = context.read<SocialService>();
    await social.loadContacts();
    if (!mounted) return;
    setState(() => _isContact = social.isPeerContact(_profile.id));
  }

  Future<void> _toggleContact() async {
    if (_isContact || _contactPending || _contactLoading) return;
    setState(() => _contactLoading = true);
    final ok = await context.read<SocialService>().sendContactRequest(
          peerId: _profile.id,
          subtitle: 'Quiere agregarte como contacto',
        );
    if (mounted) {
      setState(() {
        _contactLoading = false;
        if (ok) _contactPending = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ok ? 'Solicitud de contacto enviada' : 'No se pudo enviar la solicitud',
          ),
        ),
      );
    }
  }

  Future<void> _openMessages() async {
    await openChatWithPeer(
      context,
      peerId: _profile.id,
      name: _profile.name,
      avatarKey: _profile.avatar,
      profession: _profile.professions.isNotEmpty ? _profile.professions.first : '',
    );
  }

  List<ProfileReview> get _reviews {
    final p = _profile;
    if (p.reviews.isNotEmpty) return p.reviews;
    if (widget.isOwnProfile) {
      return ProviderDemoData.enrichedProfile(p).reviews;
    }
    return p.reviews;
  }

  void _openMenu() {
    if (widget.isOwnProfile) {
      showSettingsDrawer(context);
      return;
    }
    showAppBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.share_outlined, color: AppColors.textSecondary),
              title: const Text('Compartir perfil'),
              onTap: () async {
                Navigator.pop(ctx);
                try {
                  final url = await context.read<ProfileActionsService>().shareProfile(_profile.id);
                  await Clipboard.setData(ClipboardData(text: url));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Enlace copiado al portapapeles')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error al compartir: $e')),
                    );
                  }
                }
              },
            ),
            ListTile(
              leading: Icon(Icons.flag_outlined, color: AppColors.textSecondary),
              title: const Text('Reportar perfil'),
              onTap: () {
                Navigator.pop(ctx);
                showReportProblemFlow(context, providerId: _profile.id);
              },
            ),
            if (widget.showBackButton)
              ListTile(
                leading: const Icon(Icons.arrow_back),
                title: const Text('Volver'),
                onTap: () {
                  Navigator.pop(ctx);
                  context.pop();
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent(UserProfile p) {
    return switch (_tabIndex) {
      0 => widget.isOwnProfile
          ? OwnSkillsTab(profile: p, embeddedInScroll: true)
          : BookingTab(
              isOwnProfile: false,
              providerId: p.id,
              providerName: p.name,
              verified: p.verified,
              embeddedInScroll: true,
            ),
      1 => PortfolioTab(
          items: p.portfolio,
          isOwnProfile: widget.isOwnProfile,
          userName: p.name,
          avatarKey: p.avatar,
          userId: p.id,
          embeddedInScroll: true,
        ),
      _ => ReviewsTab(
          reviews: _reviews,
          providerId: widget.isOwnProfile ? null : p.id,
          showActions: !widget.isOwnProfile,
          embeddedInScroll: true,
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final p = _profile;

    return ColoredBox(
      color: AppColors.scaffold,
      child: CustomScrollView(
        slivers: [
          if (widget.topBar != null) SliverToBoxAdapter(child: widget.topBar),
          if (widget.isOwnProfile && !p.verified)
            SliverToBoxAdapter(
              child: VerifyAccountBanner(
                onVerifyTap: () => openVerifyIdentity(context),
              ),
            ),
          if (widget.showProfileChrome)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 8, 0),
                child: Row(
                  children: [
                    if (widget.showBackButton)
                      IconButton(
                        icon: const Icon(Icons.arrow_back, size: 22),
                        onPressed: () => context.pop(),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                      )
                    else
                      const SizedBox(width: 36),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.menu, color: AppColors.textPrimary),
                      onPressed: _openMenu,
                    ),
                  ],
                ),
              ),
            ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: widget.isOwnProfile
                  ? OwnProfileHeader(profile: p)
                  : _OtherUserHeader(
                      profile: p,
                      isContact: _isContact,
                      contactPending: _contactPending,
                      contactLoading: _contactLoading,
                      onContactToggle: _toggleContact,
                      onMessages: _openMessages,
                    ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: _ProfileTabSelector(
                isOwnProfile: widget.isOwnProfile,
                selectedIndex: _tabIndex,
                onSelected: (i) => setState(() => _tabIndex = i),
              ),
            ),
          ),
          SliverToBoxAdapter(child: _buildTabContent(p)),
          SliverToBoxAdapter(child: SizedBox(height: shellBottomInset(context))),
        ],
      ),
    );
  }
}

class _ProfileTabSelector extends StatelessWidget {
  const _ProfileTabSelector({
    required this.isOwnProfile,
    required this.selectedIndex,
    required this.onSelected,
  });

  final bool isOwnProfile;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final tabs = <({IconData icon, String label})>[
      (
        icon: isOwnProfile ? Icons.build_outlined : Icons.calendar_month_outlined,
        label: isOwnProfile ? 'Habilidades' : 'Contratar',
      ),
      (icon: Icons.photo_library_outlined, label: 'Portafolio'),
      (icon: Icons.star_outline, label: 'Reseñas'),
    ];

    return Row(
      children: List.generate(tabs.length, (i) {
        final tab = tabs[i];
        final selected = selectedIndex == i;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i < tabs.length - 1 ? 8 : 0),
            child: Material(
              color: selected ? AppColors.surfaceElevated : AppColors.card,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => onSelected(i),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: selected ? AppColors.textMuted : AppColors.border,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(tab.icon, size: 20, color: selected ? AppColors.textPrimary : AppColors.textSecondary),
                      const SizedBox(height: 4),
                      Text(
                        tab.label,
                        style: AppTypography.caption.copyWith(
                          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                          color: selected ? AppColors.textPrimary : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _OtherUserHeader extends StatelessWidget {
  const _OtherUserHeader({
    required this.profile,
    required this.isContact,
    required this.contactPending,
    required this.contactLoading,
    required this.onContactToggle,
    required this.onMessages,
  });

  final UserProfile profile;
  final bool isContact;
  final bool contactPending;
  final bool contactLoading;
  final VoidCallback onContactToggle;
  final VoidCallback onMessages;

  String get _contactLabel {
    if (isContact) return 'En contactos';
    if (contactPending) return 'Solicitud enviada';
    return 'Agregar como contacto';
  }

  @override
  Widget build(BuildContext context) {
    final p = profile;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AlworkiAvatar(avatarKey: p.avatar, radius: 36),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(p.name, style: AppTypography.titleMedium),
                      ),
                      if (p.verified) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.proximity,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'VERIFICADO',
                            style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(p.professions.join(', '), style: AppTypography.bodySmall),
                  if (p.verified) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (p.localAvailable) _StatusBadge(label: 'LOCAL', color: AppColors.localBadge),
                        if (p.localAvailable && p.remoteAvailable) const SizedBox(width: 6),
                        if (p.remoteAvailable) _StatusBadge(label: 'REMOTO', color: AppColors.remoteBadge),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: FilledButton(
                onPressed: (isContact || contactPending || contactLoading) ? null : onContactToggle,
                child: contactLoading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(_contactLabel, textAlign: TextAlign.center),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton(
                onPressed: onMessages,
                child: const Text('Mensajes'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}
