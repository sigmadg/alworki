import 'package:flutter/material.dart';

import '../../models/user_profile.dart';
import '../../services/api_client.dart';
import '../../theme/app_colors.dart';
import 'provider_profile_screen.dart';

/// Perfil de otro usuario (desde búsqueda o feed).
class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({
    super.key,
    required this.userId,
    this.fallbackName,
    this.fallbackAvatar,
  });

  final int userId;
  final String? fallbackName;
  final String? fallbackAvatar;

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  UserProfile? _profile;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final api = ApiClient();
      final data = await api.get('/api/users/${widget.userId}/profile') as Map<String, dynamic>;
      if (mounted) {
        setState(() {
          _profile = UserProfile.fromJson(data);
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _profile = UserProfile(
            id: widget.userId,
            name: widget.fallbackName ?? 'Tina Shah',
            verified: true,
            avatar: widget.fallbackAvatar ?? 'users/4.jpg',
            contacts: 0,
            professions: const ['Pintor', 'Carpintero', 'Escultor'],
            localContacts: 0,
            remoteContacts: 0,
            localAvailable: true,
            remoteAvailable: true,
            skills: const [],
            materials: const [],
            portfolio: const [],
            reviews: const [],
          );
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.scaffold,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      body: ProviderProfileScreen(
        profile: _profile!,
        showBackButton: true,
        showProfileChrome: true,
      ),
    );
  }
}
