import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../services/social_service.dart';
import '../../state/auth_controller.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../widgets/app_bottom_bar.dart';
import '../widgets/app_modal.dart';
import '../widgets/app_screen_insets.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.read<AuthController>().isLoggedIn) {
        context.read<SocialService>().loadMessages();
      }
    });
  }

  StatefulNavigationShell get navigationShell => widget.navigationShell;

  void _go(BuildContext context, int index) {
    navigationShell.goBranch(index, initialLocation: index == navigationShell.currentIndex);
  }

  void _showCreateSheet(BuildContext context) {
    showAppBottomSheet<void>(
      context: context,
      showHandle: false,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              appBottomSheetHandle(),
              const SizedBox(height: 12),
              Text('¿Qué quieres crear?', style: AppTypography.titleMedium),
              const SizedBox(height: 4),
              Text(
                'Elige una opción para compartir con la comunidad',
                style: AppTypography.sectionSubtitle,
              ),
              const SizedBox(height: 20),
              _CreateOption(
                icon: Icons.post_add,
                iconColor: AppColors.trustButton,
                title: 'Publicar un favor',
                subtitle: 'Pide ayuda o ofrece un servicio a la comunidad',
                onTap: () {
                  Navigator.pop(ctx);
                  context.push('/create-post');
                },
              ),
              _CreateOption(
                icon: Icons.photo_library_outlined,
                iconColor: AppColors.fabStart,
                title: 'Añadir a mi portafolio',
                subtitle: 'Muestra tu trabajo y atrae clientes',
                onTap: () {
                  Navigator.pop(ctx);
                  context.push('/publish-portfolio');
                },
              ),
              _CreateOption(
                icon: Icons.handyman_outlined,
                iconColor: AppColors.trustButton,
                title: 'Crear un proyecto',
                subtitle: 'Publica un trabajo y síguelo en el feed',
                onTap: () {
                  Navigator.pop(ctx);
                  context.push('/create-project');
                },
              ),
              _CreateOption(
                icon: Icons.auto_awesome,
                iconColor: AppColors.fabStart,
                title: 'Publicar historia',
                subtitle: 'Comparte algo breve con la comunidad',
                onTap: () {
                  Navigator.pop(ctx);
                  context.push('/create-story');
                },
              ),
              _CreateOption(
                icon: Icons.swap_horiz,
                iconColor: AppColors.localBadge,
                title: 'Solicitud de intercambio',
                subtitle: 'Propón intercambiar favores con alguien',
                onTap: () {
                  Navigator.pop(ctx);
                  context.push('/exchange');
                },
              ),
              _CreateOption(
                icon: Icons.smart_toy_outlined,
                iconColor: AppColors.proximity,
                title: 'Asistente con IA',
                subtitle: 'Recibe ayuda para encontrar servicios o favores',
                onTap: () {
                  Navigator.pop(ctx);
                  context.push('/chat');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final index = navigationShell.currentIndex;
    final unread = context.watch<SocialService>().unreadMessages;

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(gradient: AppColors.drawerGradient),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.swap_horiz, color: Colors.white, size: 28),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Alworki',
                    style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Encuentra servicios, intercambia favores y contrata profesionales',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13, height: 1.3),
                  ),
                ],
              ),
            ),
            _DrawerSection(title: 'Navegación'),
            ListTile(
              leading: const Icon(Icons.home_outlined),
              title: const Text('Inicio'),
              subtitle: const Text('Publicaciones de la comunidad'),
              selected: index == 0,
              onTap: () {
                Navigator.pop(context);
                _go(context, 0);
              },
            ),
            ListTile(
              leading: const Icon(Icons.grid_view_outlined),
              title: const Text('Categorías'),
              subtitle: const Text('Explora servicios por tipo'),
              selected: index == 1,
              onTap: () {
                Navigator.pop(context);
                _go(context, 1);
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Mi perfil'),
              subtitle: const Text('Portafolio y habilidades'),
              selected: index == 2,
              onTap: () {
                Navigator.pop(context);
                _go(context, 2);
              },
            ),
            ListTile(
              leading: const Icon(Icons.people_outline),
              title: const Text('Contactos'),
              subtitle: const Text('Tu red y solicitudes'),
              onTap: () {
                Navigator.pop(context);
                context.push('/contacts');
              },
            ),
            ListTile(
              leading: const Icon(Icons.chat_bubble_outline),
              title: const Text('Mensajes'),
              subtitle: const Text('Chats y cotizaciones'),
              selected: index == 3,
              onTap: () {
                Navigator.pop(context);
                _go(context, 3);
              },
            ),
            const Divider(),
            _DrawerSection(title: 'Actividad'),
            ListTile(
              leading: const Icon(Icons.notifications_outlined),
              title: const Text('Notificaciones'),
              onTap: () {
                Navigator.pop(context);
                context.push('/notifications');
              },
            ),
            ListTile(
              leading: const Icon(Icons.swap_horiz),
              title: const Text('Intercambios'),
              subtitle: const Text('Solicitudes de favores'),
              onTap: () {
                Navigator.pop(context);
                context.push('/exchange');
              },
            ),
            ListTile(
              leading: const Icon(Icons.folder_outlined),
              title: const Text('Proyectos y órdenes'),
              subtitle: const Text('Seguimiento de trabajos'),
              onTap: () {
                Navigator.pop(context);
                context.push('/projects');
              },
            ),
            const Divider(),
            ListTile(
              leading: Icon(Icons.logout, color: AppColors.deleteRed.withValues(alpha: 0.8)),
              title: const Text('Cerrar sesión'),
              onTap: () async {
                Navigator.pop(context);
                await context.read<AuthController>().logout();
                if (context.mounted) context.go('/login');
              },
            ),
          ],
        ),
      ),
      body: AppScreenInsets.shellBody(child: navigationShell),
      bottomNavigationBar: AppBottomBar(
        currentIndex: index,
        onTap: (i) => _go(context, i),
        onFabTap: () => _showCreateSheet(context),
        messageBadge: unread,
      ),
    );
  }
}

class _DrawerSection extends StatelessWidget {
  const _DrawerSection({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        title.toUpperCase(),
        style: AppTypography.caption.copyWith(
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _CreateOption extends StatelessWidget {
  const _CreateOption({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppColors.scaffold,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: AppTypography.titleSmall.copyWith(fontSize: 15)),
                      const SizedBox(height: 2),
                      Text(subtitle, style: AppTypography.caption),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: AppColors.textSecondary.withValues(alpha: 0.5)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
