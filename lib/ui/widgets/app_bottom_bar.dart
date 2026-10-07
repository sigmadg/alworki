import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

class AppBottomBar extends StatelessWidget {
  const AppBottomBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.onFabTap,
    this.messageBadge = 0,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onFabTap;
  final int messageBadge;

  static const _destinations = [
    (icon: Icons.home_outlined, selectedIcon: Icons.home, label: 'Inicio'),
    (icon: Icons.grid_view_outlined, selectedIcon: Icons.grid_view_rounded, label: 'Categorías'),
    (icon: Icons.person_outline, selectedIcon: Icons.person, label: 'Perfil'),
    (icon: Icons.chat_bubble_outline, selectedIcon: Icons.chat_bubble, label: 'Mensajes'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.navBar,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: AppColors.border.withValues(alpha: 0.5))),
        boxShadow: [
          BoxShadow(
            color: AppColors.navBar.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 6, 4, 10),
          child: Row(
            children: [
              _NavItem(
                dest: _destinations[0],
                selected: currentIndex == 0,
                onTap: () => onTap(0),
              ),
              _NavItem(
                dest: _destinations[1],
                selected: currentIndex == 1,
                onTap: () => onTap(1),
              ),
              Expanded(
                child: _FabButton(onTap: onFabTap),
              ),
              _NavItem(
                dest: _destinations[2],
                selected: currentIndex == 2,
                onTap: () => onTap(2),
              ),
              _NavItem(
                dest: _destinations[3],
                selected: currentIndex == 3,
                badge: messageBadge > 0 ? messageBadge : null,
                onTap: () => onTap(3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

typedef _NavDest = ({IconData icon, IconData selectedIcon, String label});

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.dest,
    required this.selected,
    required this.onTap,
    this.badge,
  });

  final _NavDest dest;
  final bool selected;
  final VoidCallback onTap;
  final int? badge;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.textPrimary : AppColors.textSecondary;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: selected ? AppColors.surfaceElevated : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(selected ? dest.selectedIcon : dest.icon, color: color, size: 24),
                    if (badge != null && badge! > 0)
                      Positioned(
                        right: -8,
                        top: -6,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                          decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                          child: Text(
                            badge! > 9 ? '9+' : '$badge',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                dest.label,
                style: AppTypography.navLabel.copyWith(
                  color: color,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FabButton extends StatelessWidget {
  const _FabButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(0, -14),
      child: Semantics(
        label: 'Crear publicación o solicitud',
        button: true,
        child: GestureDetector(
          onTap: onTap,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: AppColors.fabGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.fabStart.withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 30),
              ),
              const SizedBox(height: 4),
              Text(
                'Crear',
                style: AppTypography.navLabel.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
