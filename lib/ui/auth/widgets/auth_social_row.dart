import 'package:flutter/material.dart';

import '../auth_colors.dart';

class AuthSocialRow extends StatelessWidget {
  const AuthSocialRow({super.key, required this.onTap});

  final void Function(String provider) onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: Divider(color: AuthColors.underline)),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text('Acceso rápido', style: TextStyle(color: AuthColors.textMuted, fontSize: 13)),
            ),
            Expanded(child: Divider(color: AuthColors.underline)),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _SocialIcon(label: 'G', color: Colors.white, onTap: () => onTap('google')),
            const SizedBox(width: 16),
            _SocialIcon(label: 'W', color: const Color(0xFF25D366), onTap: () => onTap('whatsapp')),
            const SizedBox(width: 16),
            _SocialIcon(label: '', icon: Icons.apple, color: Colors.white, onTap: () => onTap('apple')),
            const SizedBox(width: 16),
            _SocialIcon(label: 'f', color: const Color(0xFF1877F2), onTap: () => onTap('facebook')),
          ],
        ),
      ],
    );
  }
}

class _SocialIcon extends StatelessWidget {
  const _SocialIcon({
    required this.onTap,
    required this.color,
    this.label = '',
    this.icon,
  });

  final VoidCallback onTap;
  final Color color;
  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AuthColors.underline),
          color: Colors.white.withValues(alpha: 0.08),
        ),
        alignment: Alignment.center,
        child: icon != null
            ? Icon(icon, color: color, size: 26)
            : Text(
                label,
                style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }
}
