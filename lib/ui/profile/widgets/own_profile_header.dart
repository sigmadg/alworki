import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../models/user_profile.dart';
import '../../../services/catalog_service.dart';
import '../../../services/profile_actions_service.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../../widgets/alworki_image.dart';
import '../../widgets/app_modal.dart';

class OwnProfileHeader extends StatelessWidget {
  const OwnProfileHeader({super.key, required this.profile});

  final UserProfile profile;

  Future<void> _editProfessions(BuildContext context) async {
    final ctrl = TextEditingController(text: profile.professions.join(', '));
    final ok = await showAppDialog<bool>(
      context: context,
      builder: (dlg) => AlertDialog(
        title: const Text('Editar profesiones'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            hintText: 'Pintor, Carpintero, Escultor',
          ),
          maxLines: 2,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dlg, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(dlg, true), child: const Text('Guardar')),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      final list = ctrl.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      await context.read<CatalogService>().updateProfessions(list);
    }
    ctrl.dispose();
  }

  Future<void> _share(BuildContext context) async {
    try {
      final url = await context.read<ProfileActionsService>().shareProfile(profile.id);
      await Clipboard.setData(ClipboardData(text: url));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enlace copiado al portapapeles')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _onLocalToggle(BuildContext context, bool value) {
    final catalog = context.read<CatalogService>();
    catalog.setLocalAvailable(value);
    if (!profile.verified && value && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verifica tu cuenta para activar trabajos presenciales'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogService>();
    final p = profile;
    final contacts = p.contacts > 0 ? p.contacts : 70;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
            ),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        AlworkiAvatar(avatarKey: p.avatar, radius: 40),
                        if (p.verified)
                          Positioned(
                            right: -2,
                            bottom: -2,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.verified, color: AppColors.trustButton, size: 20),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.name, style: AppTypography.titleMedium),
                          const SizedBox(height: 6),
                          InkWell(
                            onTap: () => _editProfessions(context),
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      p.professions.isEmpty
                                          ? 'Agrega tus profesiones'
                                          : p.professions.join(', '),
                                      style: AppTypography.bodySmall,
                                    ),
                                  ),
                                  const Icon(Icons.edit_outlined, size: 16, color: AppColors.trustButton),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              InkWell(
                                onTap: () => context.push('/contacts'),
                                borderRadius: BorderRadius.circular(20),
                                child: _StatChip(icon: Icons.people_outline, label: '$contacts contactos'),
                              ),
                              const SizedBox(width: 8),
                              _StatChip(
                                icon: Icons.star_outline,
                                label: '${p.reviews.length} reseñas',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 14),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Disponibilidad', style: AppTypography.titleSmall.copyWith(fontSize: 14)),
                ),
                const SizedBox(height: 4),
                Text(
                  'Indica si ofreces servicios presenciales o en línea',
                  style: AppTypography.caption,
                ),
                const SizedBox(height: 12),
                _AvailabilityTile(
                  icon: Icons.location_on_outlined,
                  label: 'Presencial (LOCAL)',
                  subtitle: p.verified ? 'Trabajos en tu zona' : 'Requiere verificación',
                  color: AppColors.localBadge,
                  value: p.verified ? p.localAvailable : false,
                  onChanged: p.verified
                      ? catalog.setLocalAvailable
                      : (_) => _onLocalToggle(context, true),
                ),
                const SizedBox(height: 8),
                _AvailabilityTile(
                  icon: Icons.wifi_outlined,
                  label: 'En línea (REMOTO)',
                  subtitle: 'Servicios a distancia',
                  color: AppColors.remoteBadge,
                  value: p.remoteAvailable,
                  onChanged: catalog.setRemoteAvailable,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _share(context),
                        icon: const Icon(Icons.share_outlined, size: 18),
                        label: const Text('Compartir'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.navBar,
                          side: const BorderSide(color: AppColors.navBar),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => _editProfessions(context),
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: const Text('Editar'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.navBar,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.scaffold,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(label, style: AppTypography.caption.copyWith(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _AvailabilityTile extends StatelessWidget {
  const _AvailabilityTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: value ? color.withValues(alpha: 0.08) : AppColors.scaffold,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value ? color.withValues(alpha: 0.35) : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: value ? color : AppColors.textSecondary, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTypography.titleSmall.copyWith(fontSize: 13)),
                Text(subtitle, style: AppTypography.caption),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: color,
            activeTrackColor: color.withValues(alpha: 0.35),
          ),
        ],
      ),
    );
  }
}
