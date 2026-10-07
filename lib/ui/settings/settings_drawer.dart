import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../state/auth_controller.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../theme/app_theme.dart';
import '../auth/verify_identity_screen.dart';
import '../widgets/app_modal.dart';

/// Menú lateral de Configuración (Figma — drawer morado desde la derecha).
Future<void> showSettingsDrawer(BuildContext context) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Configuración',
    barrierColor: kModalBarrierColor,
    transitionDuration: const Duration(milliseconds: 250),
    pageBuilder: (ctx, anim1, anim2) => const SizedBox.shrink(),
    transitionBuilder: (ctx, anim, _, __) {
      final offset = Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero).animate(
        CurvedAnimation(parent: anim, curve: Curves.easeOut),
      );
      return SlideTransition(
        position: offset,
        child: Align(
          alignment: Alignment.centerRight,
          child: _SettingsPanel(parentContext: context),
        ),
      );
    },
  );
}

class _SettingsPanel extends StatelessWidget {
  const _SettingsPanel({required this.parentContext});

  final BuildContext parentContext;

  Future<void> _confirmLogout(BuildContext context) async {
    final ok = await showAppDialog<bool>(
      context: context,
      builder: (dlg) => AlertDialog(
        backgroundColor: AppColors.card,
        surfaceTintColor: Colors.transparent,
        shape: AppTheme.appDialogShape(),
        title: Text('¿Seguro que deseas cerrar sesión?', style: AppTypography.titleMedium),
        actions: [
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.pop(dlg, true),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.localBadge,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              ),
              child: const Text('Cerrar sesión'),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(dlg, false),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.localBadge,
                side: const BorderSide(color: AppColors.localBadge),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              ),
              child: const Text('Cancelar'),
            ),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      Navigator.pop(context);
      await parentContext.read<AuthController>().logout();
      if (parentContext.mounted) parentContext.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.navBar,
      child: SafeArea(
        child: SizedBox(
          width: MediaQuery.sizeOf(context).width * 0.78,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Configuración',
                        style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              _SettingsTile(
                icon: Icons.lock_outline,
                label: 'Verificación de cuenta',
                subtitle: 'Activa trabajos presenciales',
                onTap: () {
                  Navigator.pop(context);
                  openVerifyIdentity(parentContext);
                },
              ),
              _SettingsTile(
                icon: Icons.people_outline,
                label: 'Mis contactos',
                subtitle: 'Red y solicitudes pendientes',
                onTap: () {
                  Navigator.pop(context);
                  parentContext.push('/contacts');
                },
              ),
              _SettingsTile(
                icon: Icons.link,
                label: 'Solicitud de contactos',
                subtitle: 'Gestiona quién puede contactarte',
                onTap: () {
                  Navigator.pop(context);
                  parentContext.push('/contacts?tab=1');
                },
              ),
              _SettingsTile(
                icon: Icons.remove_circle_outline,
                label: 'Cuentas bloqueadas',
                subtitle: 'Usuarios que has bloqueado',
                onTap: () {
                  Navigator.pop(context);
                  parentContext.push('/settings/blocked-contacts');
                },
              ),
              _SettingsTile(
                icon: Icons.notifications_outlined,
                label: 'Notificaciones',
                subtitle: 'Alertas de actividad',
                onTap: () {
                  Navigator.pop(context);
                  parentContext.push('/notifications');
                },
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.all(20),
                child: OutlinedButton.icon(
                  onPressed: () => _confirmLogout(context),
                  icon: const Icon(Icons.logout, color: Colors.white),
                  label: const Text('Cerrar sesión', style: TextStyle(color: Colors.white)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white38),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.subtitle,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
      title: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
      subtitle: subtitle != null
          ? Text(subtitle!, style: TextStyle(color: Colors.white.withValues(alpha: 0.65), fontSize: 12))
          : null,
      onTap: onTap,
    );
  }
}
