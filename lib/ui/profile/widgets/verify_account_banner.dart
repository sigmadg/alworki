import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../theme/app_colors.dart';

/// Banner Figma: «¡Verifica tu cuenta!» (solo trabajadores no verificados).
class VerifyAccountBanner extends StatefulWidget {
  const VerifyAccountBanner({super.key, this.onVerifyTap});

  final VoidCallback? onVerifyTap;

  @override
  State<VerifyAccountBanner> createState() => _VerifyAccountBannerState();
}

class _VerifyAccountBannerState extends State<VerifyAccountBanner> {
  bool _visible = true;

  @override
  void initState() {
    super.initState();
    _loadDismissed();
  }

  Future<void> _loadDismissed() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('verify_banner_dismissed') == true && mounted) {
      setState(() => _visible = false);
    }
  }

  Future<void> _dismiss() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('verify_banner_dismissed', true);
    if (mounted) setState(() => _visible = false);
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.fabStart.withValues(alpha: 0.15),
            const Color(0xFFFFE8E8),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.fabStart.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.fabStart.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.bolt, color: AppColors.fabStart, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: widget.onVerifyTap,
              child: const Text(
                '¡Verifica tu cuenta! Tendrás la posibilidad de realizar trabajos presenciales.',
                style: TextStyle(fontSize: 13, height: 1.35, color: AppColors.textPrimary),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18, color: AppColors.textSecondary),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            onPressed: _dismiss,
          ),
        ],
      ),
    );
  }
}
