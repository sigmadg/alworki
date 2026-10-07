import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/catalog_service.dart';
import '../../theme/app_colors.dart';
import '../settings/settings_drawer.dart';
import '../widgets/shell_tab_header.dart';
import 'provider_profile_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<CatalogService>().profile;

    return ProviderProfileScreen(
      profile: profile,
      isOwnProfile: true,
      showProfileChrome: false,
      initialTab: initialTab,
      topBar: ShellTabHeader(
        title: 'Mi perfil',
        subtitle: 'Tu portafolio, habilidades y reseñas',
        onMenuTap: () => Scaffold.of(context).openDrawer(),
        trailing: IconButton(
          icon: const Icon(Icons.settings_outlined, color: AppColors.textPrimary),
          tooltip: 'Configuración',
          onPressed: () => showSettingsDrawer(context),
        ),
      ),
    );
  }
}
