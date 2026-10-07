import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../services/api_client.dart';
import '../../services/catalog_service.dart';
import '../../services/identity_verification_service.dart';
import '../../state/auth_controller.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

/// Verificación de INE + biometría facial (open source vía backend DeepFace).
class VerifyIdentityScreen extends StatefulWidget {
  const VerifyIdentityScreen({super.key});

  @override
  State<VerifyIdentityScreen> createState() => _VerifyIdentityScreenState();
}

class _VerifyIdentityScreenState extends State<VerifyIdentityScreen> {
  final _picker = ImagePicker();
  final _curp = TextEditingController();
  int _step = 0;
  Uint8List? _ineFront;
  Uint8List? _ineBack;
  Uint8List? _selfie;
  bool _loading = false;
  IdentityVerificationResult? _result;

  @override
  void dispose() {
    _curp.dispose();
    super.dispose();
  }

  Future<void> _pick(ImageSource source, void Function(Uint8List) onBytes) async {
    final file = await _picker.pickImage(source: source, maxWidth: 2000, imageQuality: 88);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() => onBytes(bytes));
  }

  Future<void> _submit() async {
    if (_ineFront == null || _selfie == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Captura INE (frente) y selfie')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final service = IdentityVerificationService(
        ApiClient(),
        () => context.read<AuthController>().accessToken,
      );
      final result = await service.submit(
        ineFront: _ineFront!,
        selfie: _selfie!,
        ineBack: _ineBack,
        curp: _curp.text.trim().isEmpty ? null : _curp.text.trim(),
      );
      if (result.approved && mounted) {
        await context.read<CatalogService>().refresh();
      }
      if (mounted) {
        setState(() => _result = result);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(
        title: const Text('Verificar identidad'),
        backgroundColor: AppColors.navBar,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _InfoCard(),
          const SizedBox(height: 20),
          if (_result != null) _ResultCard(result: _result!)
          else ...[
            _StepIndicator(step: _step),
            const SizedBox(height: 20),
            if (_step == 0) _IntroStep(onNext: () => setState(() => _step = 1)),
            if (_step == 1)
              _PhotoStep(
                title: 'Foto frontal de tu INE',
                subtitle: 'Buena luz, sin reflejos. Debe verse tu rostro en la credencial.',
                bytes: _ineFront,
                onCamera: () => _pick(ImageSource.camera, (b) => _ineFront = b),
                onGallery: () => _pick(ImageSource.gallery, (b) => _ineFront = b),
                onNext: _ineFront != null ? () => setState(() => _step = 2) : null,
              ),
            if (_step == 2)
              _PhotoStep(
                title: 'Reverso de INE (opcional)',
                subtitle: 'Ayuda a leer CURP y clave de elector con OCR.',
                bytes: _ineBack,
                onCamera: () => _pick(ImageSource.camera, (b) => _ineBack = b),
                onGallery: () => _pick(ImageSource.gallery, (b) => _ineBack = b),
                onNext: () => setState(() => _step = 3),
                skipLabel: 'Omitir',
              ),
            if (_step == 3) ...[
              _PhotoStep(
                title: 'Selfie biométrico',
                subtitle: 'Mira a la cámara, rostro descubierto, fondo neutro.',
                bytes: _selfie,
                onCamera: () => _pick(ImageSource.camera, (b) => _selfie = b),
                onGallery: () => _pick(ImageSource.gallery, (b) => _selfie = b),
                onNext: _selfie != null ? () => setState(() => _step = 4) : null,
              ),
            ],
            if (_step == 4 && _result == null) ...[
              TextField(
                controller: _curp,
                textCapitalization: TextCapitalization.characters,
                maxLength: 18,
                decoration: InputDecoration(
                  labelText: 'CURP (recomendado)',
                  hintText: 'PEGJ850101HDFRRL09',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Si el OCR no lee tu credencial, escribe el CURP manualmente.',
                style: AppTypography.caption,
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _loading ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.trustButton,
                  minimumSize: const Size.fromHeight(48),
                ),
                child: _loading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Verificar con biometría'),
              ),
            ],
          ],
          if (_result?.approved == true)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: FilledButton(
                onPressed: () => context.go('/profile'),
                child: const Text('Ir a mi perfil'),
              ),
            ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.trustButton.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.trustButton.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.verified_user, color: AppColors.trustButton.withValues(alpha: 0.9)),
              const SizedBox(width: 8),
              Text('Verificación open source', style: AppTypography.titleSmall.copyWith(fontSize: 14)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'INE + selfie se validan dentro de Alworki. '
            'PENDIENTE: API biométrica oficial INE/CNBV. '
            'PENDIENTE: WhatsApp Business OTP. '
            'Si DeepFace no está instalado, se usa un modo local de desarrollo.',
            style: AppTypography.caption,
          ),
        ],
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.step});
  final int step;

  @override
  Widget build(BuildContext context) {
    const labels = ['Inicio', 'INE frente', 'INE reverso', 'Selfie', 'CURP'];
    return Row(
      children: List.generate(labels.length, (i) {
        final active = i <= step;
        return Expanded(
          child: Column(
            children: [
              Container(
                height: 4,
                margin: EdgeInsets.only(right: i < labels.length - 1 ? 4 : 0),
                decoration: BoxDecoration(
                  color: active ? AppColors.trustButton : AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _IntroStep extends StatelessWidget {
  const _IntroStep({required this.onNext});
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('¿Qué necesitas?', style: AppTypography.titleMedium),
        const SizedBox(height: 12),
        const _Bullet('Credencial INE/IFE vigente (frente y opcional reverso)'),
        const _Bullet('Selfie con buena iluminación'),
        const _Bullet('CURP a mano por si el OCR no la lee'),
        const SizedBox(height: 24),
        FilledButton(onPressed: onNext, child: const Text('Comenzar')),
        TextButton(
          onPressed: () => context.go('/home'),
          child: const Text('Hacerlo después'),
        ),
      ],
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 16)),
          Expanded(child: Text(text, style: AppTypography.bodySmall)),
        ],
      ),
    );
  }
}

class _PhotoStep extends StatelessWidget {
  const _PhotoStep({
    required this.title,
    required this.subtitle,
    required this.bytes,
    required this.onCamera,
    required this.onGallery,
    this.onNext,
    this.skipLabel,
  });

  final String title;
  final String subtitle;
  final Uint8List? bytes;
  final VoidCallback onCamera;
  final VoidCallback onGallery;
  final VoidCallback? onNext;
  final String? skipLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: AppTypography.titleMedium),
        const SizedBox(height: 6),
        Text(subtitle, style: AppTypography.caption),
        const SizedBox(height: 16),
        if (bytes != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.memory(bytes!, height: 180, width: double.infinity, fit: BoxFit.cover),
          )
        else
          Container(
            height: 140,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(Icons.add_a_photo_outlined, size: 48, color: AppColors.textSecondary),
          ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onCamera,
                icon: const Icon(Icons.camera_alt_outlined),
                label: const Text('Cámara'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onGallery,
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Galería'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (onNext != null)
          FilledButton(onPressed: onNext, child: const Text('Continuar')),
        if (skipLabel != null)
          TextButton(onPressed: onNext, child: Text(skipLabel!)),
      ],
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.result});
  final IdentityVerificationResult result;

  @override
  Widget build(BuildContext context) {
    final ok = result.approved;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ok ? AppColors.proximity.withValues(alpha: 0.12) : AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ok ? AppColors.proximity : AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                ok ? Icons.check_circle : Icons.hourglass_top,
                color: ok ? AppColors.proximity : AppColors.fabStart,
              ),
              const SizedBox(width: 8),
              Text(
                ok ? '¡Cuenta verificada!' : 'Revisión en proceso',
                style: AppTypography.titleSmall,
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...result.messages.map((m) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(m, style: AppTypography.bodySmall),
              )),
          if (result.curp != null && result.curp!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text('CURP: ${result.curp}', style: AppTypography.caption),
            ),
        ],
      ),
    );
  }
}

Future<void> openVerifyIdentity(BuildContext context) async {
  final logged = context.read<AuthController>().isLoggedIn;
  if (!logged) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Inicia sesión para verificar tu identidad')),
    );
    context.go('/login');
    return;
  }
  await context.push('/verify-identity');
}
